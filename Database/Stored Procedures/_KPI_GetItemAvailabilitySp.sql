USE [KPI_App]
GO

/****** Object:  StoredProcedure [dbo].[_KPI_GetItemAvailabilitySp]    Script Date: 08/30/2017 15:41:03 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Jim Franz
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE.[dbo].[_KPI_GetItemAvailabilitySp](
	-- Add the parameters for the stored procedure here
   @Item					ItemType = NULL
   ,@WHouse                 WhseType = NULL
   ,@RPUf_Itm_QtyAvail		INT		OUTPUT
)AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here

	SELECT 
	  @RPUf_Itm_QtyAvail= (i.qty_on_hand - (i.qty_alloc_co + i.qty_rsvd_co + i.alloc_trn)) from itemwhse_mst i with (NOLOCK) where i.item = @Item and i.whse = @WHouse
END

GO


