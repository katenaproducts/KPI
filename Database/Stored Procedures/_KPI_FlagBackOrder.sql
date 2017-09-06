USE [KPI_App]
GO

/****** Object:  StoredProcedure [dbo].[_KPI_FlagBackOrder]    Script Date: 08/30/2017 15:41:00 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



-- =============================================
-- Author:	    Donika Elezaj
-- Create date: 08_04_17

-- =============================================
CREATE PROCEDURE [dbo].[_KPI_FlagBackOrder]
	-- Add the parameters for the stored procedure here
	@PCoNum  CoNumType
AS
BEGIN
	

update co_mst
set UF_BackOrder = 'Y' where co_num     =  @PCoNum    
								
END



GO


