USE [KPI_App]
GO

/****** Object:  StoredProcedure [dbo].[KPI_CheckAutoItemOnOrderSp]    Script Date: 08/30/2017 15:50:18 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO






CREATE PROCEDURE [dbo].[KPI_CheckAutoItemOnOrderSp]
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
      
      INSERT INTO @ExclusionList
      SELECT DISTINCT Uf_AutoCreatedItem,family_code FROM famcode WHERE ISNULL(Uf_AutoCreatedItem,'') <> ''
      
      DECLARE @ItemList TABLE
      (
		Itm ItemType
		,Descr DescriptionType
      )
      
      INSERT INTO @ItemList
      SELECT DISTINCT item,description FROM coitem WITH (NOLOCK),@ExclusionList Exc 
		WHERE FamCdItem = item AND coitem.co_num = @conum
      
      IF EXISTS(SELECT Itm FROM @ItemList)
      BEGIN
		set @infobar = 'Please delete automated Item(s) manually' + CHAR(13) + CHAR(10)
		SELECT @infobar = @infobar + Itm + ' - ' + Descr FROM @ItemList
      END
END





GO


