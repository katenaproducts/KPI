USE [KPI_App]
GO

/****** Object:  StoredProcedure [dbo].[_KPI_OrderLineSeq]    Script Date: 08/30/2017 15:41:11 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO





CREATE PROCEDURE [dbo].[_KPI_OrderLineSeq] 
(
  @CoNum             CoNumType     = NULL
) 
 
AS


declare @count integer

declare @tot_count integer
declare @Min_Item ItemType
declare @Temp_Line integer

declare @CurrentItem ItemType
declare @CurrentSeq tinyint
	
set @CurrentItem = ''
set @CurrentSeq = 0

set @tot_count = 0

select @tot_count = count(1) from coitem_mst (nolock) where coitem_mst.co_num = @CoNum  
if @tot_count <= 1 return

set @tot_count = 0
select @tot_count = count(1) from coitem_mst (nolock) where coitem_mst.co_num = @CoNum  and qty_shipped > 0
if @tot_count > 0 return	

set @tot_count = 0
select @tot_count = count(1) from co_mst (nolock) where co_mst.co_num = @CoNum and ISNULL(Uf_Reseq, 0) = 1
if @tot_count = 1 return

update co_mst
set Uf_Reseq = 1 where co_mst.co_num = @CoNum 

-- now it is reseq, will not go through this routine again
   
update coi
set Uf_KPISeq = 0 
from coitem_mst coi where co_num = @CoNum



set @tot_count = 0
select @tot_count = count(1) from coitem_mst (nolock) where coitem_mst.co_num = @CoNum  
set @count = 1 

declare @IndexLine int 
set @IndexLine  = 1
select top 1
	@Min_Item = coi.item,
	
	@CurrentSeq = coi.co_line
	from coitem_mst coi (nolock) where coi.co_num = @CoNum order by co_line asc

while (@count <= @tot_count )
begin


        while (1=1)
            begin
               set @temp_line = @CurrentSeq
               
               select top 1 
				
				@CurrentSeq = coi.co_line,
				@CurrentItem = coi.item 
	
                from coitem_mst coi 
			    
			        where
			            coi.Co_Num = @CoNum and
						coi.item <> @Min_Item and
						coi.co_line > @Temp_Line and
						Uf_KPISeq = 0 order by co_line asc
			    
			    if @@ROWCOUNT = 0 
			           break
			    
			   --if @CurrentItem like 'K3%' or @Min_Item like 'K3'
			  
				declare @result tinyint
				
				
				set @result = 0
				
	            execute [KPI_App].[dbo].[_KPI_Item1GreaterItem2] 
							 @Min_Item,
							 @CurrentItem,							
							 @result OUTPUT
							
				--select 'after compare' +  @IndexLine, +  @Min_Item as Max_item1, @CurrentItem as current_item2, @result		
	            if @result = 1 
	            
	            begin   
	                   
	                   set @IndexLine = @CurrentSeq
						--select'after compare', @CurrentItem, @Min_Item						
					   set @Min_Item = @CurrentItem
				end
			
				 
			end
			
			
			--select @Count , @IndexLine, @Min_Item as MinItem
			
			update coitem_mst
			set Uf_KPISeq = @Count
			where 
				co_num = @CoNum and
				co_line = @IndexLine 
		    and Uf_KPISeq = 0
		
		
		
		-- initialize for next loop		
		
			select 
					 
					@Count = @Count + 1
				
			 select top 1 
				
				@temp_line = coi.co_line,
				@Min_Item = coi.item,
				@CurrentSeq = coi.co_line
				
                from coitem_mst coi 
			    where 
			    
			        coi.Co_Num = @CoNum 
			    and Uf_KPISeq = 0
			    
			    order by co_line asc		
	            set  @IndexLine = @temp_line 
	

end

update coitem_mst
			set co_line = Uf_KPISeq 
			where 
				co_num = @CoNum and
				Uf_KPISeq > 0
				
				
							
		
				


GO


