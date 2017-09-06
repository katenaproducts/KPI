USE [KPI_App]
GO

/****** Object:  StoredProcedure [dbo].[KPI_AutoItemOnOrderSp]    Script Date: 08/30/2017 15:50:14 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO





CREATE PROCEDURE [dbo].[KPI_AutoItemOnOrderSp]
(
	@conum CoNumType
	,@infobar Infobartype = '' output
)
AS
BEGIN

 		set @infobar = ''
		
      DECLARE @ExclusionList TABLE
      (
		FamCdItem ItemType
		,FamCode NVARCHAR(10)
      )
      
      DECLARE @ItemToAddList TABLE
      (
		Item ItemType
		,Qty DECIMAL(18,9)
      )
      
      DECLARE @Itm ItemType
			  ,@Qty DECIMAL(18,9)
      
      INSERT INTO @ExclusionList
      SELECT DISTINCT Uf_AutoCreatedItem,family_code FROM famcode WHERE ISNULL(Uf_AutoCreatedItem,'') <> ''
      
      INSERT INTO @ExclusionList 
         Select item, family_code from item_mst where ISNULL(Uf_Itm_ExcludeFromAutoAdd,'') = 1
         
--      INSERT INTO @ExclusionList 
--         VALUES('K20-2135', '023')
         
      
      DECLARE @i INT
		,@CoStat NCHAR(1)
		,@CoExlude INT
		,@ExistShippedLine INT
		,@ExistItemToAddLine INT
		,@SumQty INT
		,@SiteRef SiteType
		,@shipped_over_ordered_qty_tolerance TolerancePercentType
		,@shipped_under_ordered_qty_tolerance TolerancePercentType
		,@transport TransportType
		,@cocustnum CustNumType
		,@cocustseq CustSeqType
		,@nextcoline INT
		,@loop INT = 0

      DECLARE
		@co_num VARCHAR(10)
		,@co_line SMALLINT
		,@co_release SMALLINT
		,@item VARCHAR(30)
		,@qty_ordered DECIMAL(19,8)
		,@Uf_Itm_ExcludeFromAutoAdd SMALLINT
		
			DECLARE #coitemIupCrs CURSOR LOCAL STATIC READ_ONLY
			FOR SELECT
				co_num
				,co_line
				,co_release
				,item
				,qty_ordered
--				,b.Uf_Itm_ExcludeFromAutoAdd
				
			FROM coitem WITH (NOLOCK) WHERE co_num = @conum --and b.Uf_Itm_ExcludeFromAutoAdd = 0
			

		OPEN #coitemIupCrs
			WHILE 1=1
			BEGIN /* cursor loop */
				FETCH #coitemIupCrs INTO
					@co_num
					,@co_line
					,@co_release
					,@item
					,@qty_ordered
						

			IF @@FETCH_STATUS = -1
				BREAK
				
				DELETE FROM @ItemToAddList
				
				
				IF NOT @item IN (SELECT DISTINCT FamCdItem FROM @ExclusionList)
				BEGIN
					SET @ExistShippedLine = 0
					SET @ExistItemToAddLine = NULL
					SELECT @CoStat = stat,@CoExlude = ISNULL(Uf_ExcludeAutoItemOnOrder,0),@cocustnum = cust_num,@cocustseq = cust_seq FROM co WITH (NOLOCK) WHERE co.co_num = @co_num
					IF EXISTS(SELECT top 1 1 FROM coitem WITH (NOLOCK) WHERE coitem.co_num = @co_num and qty_shipped <> 0) SET @ExistShippedLine = 1

					IF @CoStat = 'O' and @ExistShippedLine = 0 and @CoExlude = 0
					BEGIN	--Order status allow process
						SELECT @SiteRef = orig_site 
							,@shipped_over_ordered_qty_tolerance = shipped_over_ordered_qty_tolerance
							,@shipped_under_ordered_qty_tolerance = shipped_under_ordered_qty_tolerance
							,@transport = (SELECT transport FROM shipcode WITH (NOLOCK) WHERE shipcode.ship_code = co.ship_code)
						FROM co WITH (NOLOCK) WHERE co_num = @co_num
						
						SET @nextcoline = (SELECT top 1 co_line FROM coitem WITH (NOLOCK) WHERE coitem.co_num = @co_num ORDER BY co_line DESC)
						
						INSERT INTO @ItemToAddList
						SELECT el.FamCdItem,SUM(qty_ordered) 
							FROM coitem WITH (NOLOCK),
								item WITH (NOLOCK),
								famcode fc WITH (NOLOCK),
								@ExclusionList el
							WHERE coitem.item = item.item 
								AND coitem.co_num = @co_num
								AND item.family_code = fc.family_code
								AND item.family_code = el.famcode
								AND NOT coitem.item in (SELECT DISTINCT FamCdItem FROM @ExclusionList)
							GROUP BY el.FamCdItem
						
						
						
						DECLARE CurCrs CURSOR LOCAL STATIC READ_ONLY FOR 
						SELECT Item,Qty FROM @ItemToAddList

						OPEN CurCrs

						WHILE (1 = 1) 
						BEGIN
							
							FETCH CurCrs INTO 
								@Itm,@Qty
							IF @@FETCH_STATUS = -1 BREAK	
							--Cursor Execution
								--Test if item already exist in order
								SELECT TOP 1 @ExistItemToAddLine = co_line FROM coitem WITH (NOLOCK) 
									WHERE coitem.item = @Itm 
									AND coitem.co_num = @co_num
									
								IF @ExistItemToAddLine IS NULL AND @Qty <> 0
								BEGIN
									--add line
									SET @loop = @loop + 1
									
									INSERT INTO coitem (co_num,co_line,co_release,item,description,whse
										,u_m,ref_type,ship_site,qty_ordered,qty_ordered_conv,due_date,stat,co_orig_site,shipped_over_ordered_qty_tolerance
										,shipped_under_ordered_qty_tolerance,transport)
									VALUES (
										@co_num
										,@nextcoline + @loop
										,0
										,@Itm
										,(SELECT description FROM item WITH (NOLOCK) WHERE item = @Itm)
										,(SELECT whse FROM co WITH (NOLOCK) WHERE co_num = @co_num)
										,(SELECT u_m FROM item with (nolock) where item = @Itm)
										,'I'
										,@SiteRef
										,@Qty
										,@Qty
										,isnull((SELECT TOP 1 due_date FROM coitem WITH (NOLOCK) WHERE co_num = @co_num ORDER BY co_line DESC),GETDATE())
										,@CoStat
										,@SiteRef
										,@shipped_over_ordered_qty_tolerance
										,@shipped_under_ordered_qty_tolerance
										,@transport
									)
																											
								END
								ELSE
								BEGIN
									--update existing line
									IF @Qty = 0
									BEGIN --Qty = 0 , line should be deleted
										
										INSERT INTO DefineVariables (ConnectionID,ProcessID,VariableName,VariableValue) 
											SELECT dbo.SessionIDSp(),@@SPID,'SkipTrigger',2
										
										
										UPDATE coitem SET qty_ordered=@Qty, qty_ordered_conv=@Qty
											WHERE co_line = @ExistItemToAddLine 
												AND co_num = @co_num
												
										DELETE
											FROM DefineVariables WITH (ROWLOCK)
											WHERE ConnectionID = dbo.SessionIDSp()
											  AND ProcessID = @@SPID
											  AND VariableName = 'SkipTrigger'
											  
										DELETE FROM coitem
											WHERE co_line = @ExistItemToAddLine 
												AND co_num = @co_num
									END
									ELSE
									BEGIN
										
										INSERT INTO DefineVariables (ConnectionID,ProcessID,VariableName,VariableValue) 
											SELECT dbo.SessionIDSp(),@@SPID,'SkipTrigger',2
										
										
										UPDATE coitem SET qty_ordered=@Qty, qty_ordered_conv=@Qty
											WHERE co_line = @ExistItemToAddLine 
												AND co_num = @co_num
												
										DELETE
											FROM DefineVariables WITH (ROWLOCK)
											WHERE ConnectionID = dbo.SessionIDSp()
											  AND ProcessID = @@SPID
											  AND VariableName = 'SkipTrigger'
									END
								END
							--End Cursor Execution
						END
						CLOSE CurCrs 
						DEALLOCATE CurCrs 
						
					END
					ELSE
					BEGIN
					 set @i = 0
					END
				END


		END
		CLOSE #coitemIupCrs
		DEALLOCATE #coitemIupCrs
END




GO


