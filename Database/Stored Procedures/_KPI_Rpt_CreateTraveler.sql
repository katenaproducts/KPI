USE [KPI_App]
GO

/****** Object:  StoredProcedure [dbo].[_KPI_Rpt_CreateTraveler]    Script Date: 08/30/2017 15:41:27 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



-- =============================================

-- =============================================
CREATE PROCEDURE [dbo].[_KPI_Rpt_CreateTraveler]
 (@PONum    PoNumType	 = NULL,
  @username nvarchar(30) = null,
  @Process  nvarchar(1) -- P(rocess), (R)eprint

)AS

declare @ID nvarchar(50)
Set @ID = convert(nvarchar(50), dbo.getsitedate(Getdate()))

	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    insert into dbo._KPI_Traveler (Receipt_ID, Trans_num,po_num)
    select @ID,  mt.trans_num, @PONum
    from matltran_mst mt (nolock) where 
    mt.trans_type = 'R' and 
    mt.ref_num = @PONum and 
    mt.CreatedBy = @username 
    and
    mt.trans_num not in
    (select trans_num from dbo._KPI_Traveler tr (nolock) where tr.po_num = mt.ref_num) 
    

    -- Insert statements for procedure here
	SELECT 
	  a.trans_num,
	  a.trans_type,
	  a.item,
	  a.qty,
	  c.description,
	  a.lot,
	  a.whse,
	  a.ref_num,
	  a.ref_line_suf,
	  a.ref_type,
	  b.vend_num,
	  d.name,
	  d.country,
	  e.iso_country_code,
	  c.uf_Itm_TravelerID
	FROM matltran_mst a (nolock)
	    inner join po_mst b (nolock) on a.ref_num = b.po_num
	    inner join item_mst c (nolock) on a.item = c.item
	    inner join vendaddr_mst d (nolock) on b.vend_num = d.vend_num
	    inner join country_mst e (nolock) on d.country = e.country
	    join dbo._KPI_Traveler tr (nolock) on tr.trans_num = a.trans_num and
	    tr.Receipt_ID = @ID




GO


