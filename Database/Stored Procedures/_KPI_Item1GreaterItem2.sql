USE [KPI_App]
GO

/****** Object:  StoredProcedure [dbo].[_KPI_Item1GreaterItem2]    Script Date: 08/30/2017 15:41:08 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



CREATE procedure [dbo].[_KPI_Item1GreaterItem2] 
(
  @Item1 ItemType = null,
  @Item2 ItemType = null,
  @result tinyint output
 
 )

 as 
BEGIN


  set @Result = 0
  
  set @Item1 = ISNULL(@Item1, '')
  set @Item2 = ISNULL(@Item2, '')
  
 if @Item1 = '' begin
				 set @result = 0
				 return
				end
if @Item2 = '' begin
				 set @result = 1
				 return
				end
  
 -- if one of the items is numerc, order them alphabetically
 if ISNUMERIC(@Item1) = 1 and ISNUMERIC(@Item2) = 1
 begin
 
    if convert(integer,@Item1) >= convert(integer,@Item2) set @Result = 1
    else set @Result = 0
   
 end
 
 
 -- both can not be converted to numeric values
  declare @Segment1 nvarchar(20)
  declare @segment2 nvarchar(20)
  declare @seg1Num integer
  declare @seg2Num integer
  declare @Prefix1 nvarchar(10)
  declare @Prefix2 nvarchar(10)
  
  declare @CurInd1 tinyint
  set @CurInd1 = 0
  
  declare @CurInd2 tinyint
  set @CurInd2 = 0
  
 
                        
 
        while (1=1)
      	begin
						
						
						set @Prefix1 = ''
						Set @Prefix2 = ''
						set @CurInd1 = CHARINDEX('-', @Item1, 1)
						set @CurInd2 = CHARINDEX('-', @Item2, 1)
						
  
						if @CurInd1 > 0 set @Segment1 = SUBSTRING(@item1, 1, @CurInd1 - 1)
						else set @Segment1 = @Item1
						
						while ISNUMERIC(@Segment1) = 0
						begin
							set @Prefix1 = @Prefix1 + SUBSTRING(@Segment1 , 1, 1)
							if len(@Segment1) > 1 set @Segment1 = SUBSTRING(@Segment1, 2, len(@Segment1) - 1)
							else break
						end
						
						if @CurInd2 > 0 set @Segment2 = SUBSTRING(@item2, 1, @CurInd2 - 1)
						else set @segment2 = @Item2
						
						while ISNUMERIC(@Segment2) = 0
						begin
							set @Prefix2 = @Prefix2 + SUBSTRING(@Segment2 , 1, 1)
							if len(@Segment2) > 1 set @Segment2 = SUBSTRING(@Segment2, 2, len(@Segment2) - 1)
							else break
						end
						
						--select @Prefix1, @Prefix2, @Segment1, @segment2
					     if ISNUMERIC(@Segment1) = 1 set @seg1Num = CONVERT(integer, @Segment1)
						 if ISNUMERIC(@Segment2) = 1 set @seg2Num = CONVERT(integer, @Segment2)
						
						if @Prefix1 > @Prefix2 set @Result = 1
						if @Prefix1 < @Prefix2 set @Result = 0
						if @Prefix1 <> @Prefix2 break
						
						if @seg1Num > @seg2Num 
												begin
													set @Result = 1	
													break
												end
																
		                if @seg1Num < @seg2Num
										begin
											set @Result = 0
											break
										end
		                
		                
		                if @Prefix1 + @Segment1 = @Item1 and 
		                   @Prefix2 + @segment2 = @Item2 and
		                   @Segment1 = @segment2 
		                   begin
							set @Result = 0
							break
		                   end
		                
		                set @Prefix1 = ''
						Set @Prefix2 = ''
						if @CurInd1 > 0 and @CurInd1 < len(@Item1)
						    set @item1 = SUBSTRING(@Item1, @CurInd1 + 1, len(@Item1) - @CurInd1)
						
		                if @CurInd2 > 0 and @CurInd2 < len(@Item2)
						    set @item2 = SUBSTRING(@Item2, @CurInd2 + 1, len(@Item2) - @CurInd2)
		                
		end
  

END

GO


