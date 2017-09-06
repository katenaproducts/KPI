USE [KPI_App]
GO

/****** Object:  StoredProcedure [dbo].[CLM_OrderShippingSp]    Script Date: 09/06/2017 11:21:53 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

/* $Header: /ApplicationDB/Stored Procedures/CLM_OrderShippingSp.sp 45    4/29/15 10:50p Shu $  */
/*
***************************************************************
*                                                             *
*                           NOTICE                            *
*                                                             *
*   THIS SOFTWARE IS THE PROPERTY OF AND CONTAINS             *
*   CONFIDENTIAL INFORMATION OF INFOR AND/OR ITS AFFILIATES   *
*   OR SUBSIDIARIES AND SHALL NOT BE DISCLOSED WITHOUT PRIOR  *
*   WRITTEN PERMISSION. LICENSED CUSTOMERS MAY COPY AND       *
*   ADAPT THIS SOFTWARE FOR THEIR OWN USE IN ACCORDANCE WITH  *
*   THE TERMS OF THEIR SOFTWARE LICENSE AGREEMENT.            *
*   ALL OTHER RIGHTS RESERVED.                                *
*                                                             *
*   (c) COPYRIGHT 2008 INFOR.  ALL RIGHTS RESERVED.           *
*   THE WORD AND DESIGN MARKS SET FORTH HEREIN ARE            *
*   TRADEMARKS AND/OR REGISTERED TRADEMARKS OF INFOR          *
*   AND/OR ITS AFFILIATES AND SUBSIDIARIES. ALL RIGHTS        *
*   RESERVED.  ALL OTHER TRADEMARKS LISTED HEREIN ARE         *
*   THE PROPERTY OF THEIR RESPECTIVE OWNERS.                  *
*                                                             *
***************************************************************
*/

/* $Archive: /ApplicationDB/Stored Procedures/CLM_OrderShippingSp.sp $
 *
 * SL9.00 45 194092 Shu Wed Apr 29 22:50:13 2015
 * Coding for RS6710 - 1-Pick/Pack/Ship-Unship Shipments
 * Issue 194092(RS6710): Change  QTS calculation.
 *
 * SL9.00 44 192166 pgross Fri Mar 06 09:24:41 2015
 * Order Shipping displayed a single line of Customer Order twice after applied SL191822
 * corrected JOIN to taxcode
 *
 * SL9.00 43 178654 Ltaylor2 Fri May 16 14:48:38 2014
 * Order Shipping not showing VAT ID message
 * Issue 178654 - added additional output fields
 *
 * SL8.04 42 166647 Lqian2 Mon Aug 26 01:21:22 2013
 * No order line displaying in the grid in the form ‘Order Shipping’ after changing CO Line\Release Status to‘Ordered And Filled’
 * Issue 166647, Show partically shipped order line with zero qty remaining and PPS qty hold.
 *
 * SL8.04 41 RS6252 Ezhang1 Mon Jun 03 04:53:16 2013
 * RS6252
 *
 * SL8.04 40 RS6252 Ezhang1 Wed May 29 04:45:49 2013
 * RS6252
 *
 * SL8.04 39 RS5421 Ezhang1 Mon Nov 12 02:11:04 2012
 * RS5421
 * Add DerNegShipmentQty into customer load out put
 *
 * SL8.04 38 149028 pgross Wed Aug 01 13:44:27 2012
 * Order Shipping, Item Issued by Location and Lot tracked does not display
 * return a row for lot-tracked items with no lots
 *
 * SL8.04 37 150254 sturney Mon Jul 09 17:45:35 2012
 * The Transaction field on the Electronic Signature Required form doesn't distinguish between Regular orders and Blanket Orders.
 * Issue 150254  Added CoType to return as UbCoType property.
 *
 * SL8.03 36 147740 Lchen3 Tue Mar 20 02:57:39 2012
 * Quantity should be shown with ordered Qty from CO instead of 0
 * issue 147740
 * non-inventry item quantity = QtyOrdered - QtyShipped
 *
 * SL8.03 35 147342 pgross Mon Feb 27 16:11:26 2012
 * The Order Shipping forms locks up if the CO line does not have quantity on hand and the second CO line is a non-inventory item.
 * create @tt_ship records for non-inventory items
 *
 * SL8.03 34 139013 calagappan Fri Oct 07 16:56:41 2011
 * There is no cancel option when overshipping on co line
 * Retrieve coitem RecordDate
 *
 * SL8.03 33 140444 btian Mon Jul 25 05:41:32 2011
 * CO Line/Release manufacturer values not showing up in the grid.
 * 140444,  add 4 output parameters ManufacturerID, ManufacturerItem, ManufacturerName and ManufacturerItemDesc
 *
 * SL8.03 32 RS4892 Bli2 Tue Jun 07 23:08:50 2011
 * RS4892 - correct the returned qty on hand
 *
 * SL8.03 31 RS4892 Bli2 Fri Jun 03 04:42:15 2011
 * RS4892 - add one more return property
 *
 * SL8.03 30 RS4892 Bli2 Fri Jun 03 03:41:49 2011
 * RS4892 - Subtract qty_contained from qty_on_hand.
 * Call CLM_ContainerShippingSp when container num is not null.
 *
 * SL8.03 29 137691 Bli2 Fri Jun 03 03:26:51 2011
 * System hangs on selection of some orders
 * Isue 137691 - add the break condition for inventory item
 *
 * SL8.03 28 137377 Jgao1 Sun May 15 23:21:20 2011
 * Stored Procedures need to be cleaned up
 * IS137377:Delete commented code
 *
 * SL8.03 27 RS4410 Ezi Wed Apr 13 03:58:56 2011
 * RS 4410 – Dimensional Inventory Transactions
 *
 * SL8.03 26 rs3639 Jpan2 Tue Mar 01 05:07:53 2011
 * RS3639 Allow handle Non Inventory Item.
 *
 * SL8.03 25 133085 calagappan Wed Oct 13 14:10:27 2010
 * Additional lines showing for releases and item is lot tracked
 * Do not display multiple rows that have zero quantity to ship for a CO, line, and release
 *
 * SL8.02 24 rs4588 Dahn Thu Mar 04 10:24:51 2010
 * RS4588 Copyright header changes
 *
 * SL8.02 23 rs4588 Dahn Thu Mar 04 09:34:06 2010
 * RS4588 Copyright header changes
 *
 * SL8.02 22 126712 pgross Tue Jan 12 08:54:41 2010
 * Order Shipping - order line for lot tracked item does not display
 * lot-tracked items with zero quantity at nettable locations which issue by location will now appear in the result set
 *
 * SL8.01 21 rs3953 Vlitmano Tue Aug 26 16:42:33 2008
 * RS3953 - Changed a Copyright header?
 *
 * SL8.01 20 rs3953 Vlitmano Mon Aug 18 15:07:36 2008
 * Changed a Copyright header information(RS3959)
 *
 * SL8.00 19 102790 hcl-singind Wed Jun 27 03:18:06 2007
 * Order shipping form is displaying a duplicated order line
 * Issue # 102790
 * Modified the logic to set the value of Quantity to Ship.
 *
 * SL8.00 18 rs2968 nkaleel Fri Feb 23 00:55:54 2007
 * changing copyright information
 *
 * SL8.00 17 98925 hcl-tiwasun Thu Feb 01 23:36:38 2007
 * Ready field on Customer Order lines displays incorrect value if unit of measure conversion is applicable
 * Issue# 98925
 * Modified Stored Procedure CLM_OrderShippingSp so that it displays correct quantity available.
 *
 * SL8.00 16 RS2968 prahaladarao.hs Thu Jul 13 02:44:11 2006
 * RS 2968, Name change CopyRight Update.
 *
 * SL8.00 15 RS2968 prahaladarao.hs Tue Jul 11 05:23:03 2006
 * RS 2968
 * Name change CopyRight Update.
 *
 * SL8.00 14 93740 pgross Mon Apr 17 15:05:02 2006
 * Order Shipping form incorrectly shows negative Quantity Available
 * exclude the current line's requirements from the Available calculation
 *
 * SL7.05 13 91818 NThurn Fri Jan 06 14:24:03 2006
 * Inserted standard External Touch Point call.  (RS3177)
 *
 * SL7.04 12 91485 hcl-kumanav Fri Dec 30 01:07:04 2005
 * Order Shipping form does not default with correct quantities for order lines, based on customer order lines due date value.
 * Issue 91485
 * Added due_date column in order by clause of main cursor coitemcrs select statement
 *
 * SL7.04 11 91110 hcl-singind Mon Dec 26 07:06:48 2005
 * Issue #: 91110
 * Added "WITH (READUNCOMMITTED)" to co and item Select Statement.
 *
 * SL7.04 10 89822 Hcl-kannvai Thu Oct 13 08:08:55 2005
 * Text appended to item description when adding item on COLine does not carry forward and appear on other forms.
 * Checked in for Issue #89822.
 * The column item.Description is changed to coitem.Description in the final select query.
 *
 * SL7.04 9 88855 Grosphi Thu Aug 25 08:04:16 2005
 * Order Shipping shows the wrong quantity available calculation
 * exclude qty_shipped from Available Quantity calculation
 *
 * SL7.04 8 86800 Hcl-kavimah Thu May 05 06:30:48 2005
 * Even though inventory parameters allow negative on hand if no LOTS with positive stock are available the customer order line affected will not be displayed.
 * Issue 86800,
 *
 * modfied the condition when Issuedby = 'LOT'
 *
 * SL7.04 7 86206 Hcl-dixichi Thu Mar 03 23:05:07 2005
 * Syteline is not assigning default lot# during CO Shipping
 * Checked-in for issue 86206
 * Reverting back the change done for issue 84089.
 *
 * $NoKeywords: $
 */
CREATE PROCEDURE [dbo].[CLM_OrderShippingSp] (
   @CoNum CoNumType = NULL,
   @StartDate DateType = NULL,
   @EndDate DateType = NULL,
   @CoitemStatuses nvarchar(2) = NULL,
   @CurWhse WhseType = NULL,
   @ContainerNum ContainerNumType,
   @Infobar InfobarType OUTPUT
) AS

   -- Check for existence of Generic External Touch Point routine (this section was generated by SpETPCodeSp and inserted by CallETPs.exe):
   IF OBJECT_ID(N'dbo.EXTGEN_CLM_OrderShippingSp') IS NOT NULL
   BEGIN
      DECLARE @EXTGEN_SpName sysname
      SET @EXTGEN_SpName = N'dbo.EXTGEN_CLM_OrderShippingSp'
      -- Invoke the ETP routine, passing in (and out) this routine's parameters:
      DECLARE @EXTGEN_Severity int
      EXEC @EXTGEN_Severity = @EXTGEN_SpName
         @CoNum
         , @StartDate
         , @EndDate
         , @CoitemStatuses
         , @CurWhse
         , @ContainerNum
         , @Infobar OUTPUT
 
      -- ETP routine can RETURN 1 to signal that the remainder of this standard routine should now proceed:
      IF @EXTGEN_Severity <> 1
         RETURN @EXTGEN_Severity
   END
   -- End of Generic External Touch Point code.
 
DECLARE
   @Site SiteType

IF @CoNum IS NULL
   RETURN 0

DECLARE
   @Severity INT

SET @Severity = 0

IF @ContainerNum IS NOT NULL
BEGIN
   EXEC @Severity = dbo.CLM_ContainerShippingSp
      @CoNum
      , @ContainerNum
      , @CurWhse
      , @Infobar

   RETURN @Severity
END

SET @StartDate = isnull(dbo.MidnightOf(@StartDate), dbo.LowDate())
SET @EndDate = isnull(dbo.DayEndOf(@EndDate), dbo.HighDate())
SET @CoitemStatuses = isnull(@CoitemStatuses, 'O')

-- We need this later
DECLARE @DefWhse WhseType
SELECT @DefWhse = def_whse FROM invparms with (readuncommitted)

IF @CurWhse IS NULL
   SET @CurWhse = @DefWhse

SELECT @Site = site FROM parms with (readuncommitted)

declare
 @WItemlocRowpointer RowPointerType
,@WItemlocItem ItemType
,@WItemlocLoc LocType
,@WItemlocLot LotType
,@WItemlocQtyOnHand QtyUnitType
,@__LookAheadCoitem__Eof Flag
,@__LookAheadCoitem__FirstOfCoLine Flag
,@__LookAheadCoitem__FirstOfCoNum Flag
,@__LookAheadCoitem__FirstOfCoRelease Flag
,@__LookAheadCoitem__LastOfCoLine Flag
,@__LookAheadCoitem__LastOfCoNum Flag
,@__LookAheadCoitem__LastOfCoRelease Flag
,@__LookAheadCoitemCoLine CoLineType
,@__LookAheadCoitemCoNum CoNumType
,@__LookAheadCoitemCoRelease CoReleaseType
,@__LookAheadCoitemItem ItemType
,@__LookAheadCoitemQtyOrdered QtyUnitNoNegType
,@__LookAheadCoitemQtyReady QtyUnitNoNegType
,@__LookAheadCoitemQtyShipped QtyUnitNoNegType
,@__LookAheadCoitemRefType RefTypeIJKPRTType
,@__LookAheadCoitemRowpointer RowPointerType
,@__LookAheadCoitemStat CoitemStatusType
,@__LookAheadCoitemUM UMType
,@__LookAheadCoitemWhse WhseType
,@RsvdInvRefNum CoNumType
,@RsvdInvRefLine CoLineType
,@RsvdInvRefRelease CoReleaseType
,@RsvdInvLoc LocType
,@RsvdInvLot LotType
,@RsvdInvQtyRsvd QtyUnitNoNegType
,@ItemlocRowpointer RowPointerType
,@ItemlocItem ItemType
,@ItemlocLoc LocType
,@ItemlocQtyOnHand QtyUnitType
,@ItemlocQtyRsvd QtyUnitType
,@ItemlocWhse WhseType
,@ItemlocRank ItemlocRankType
,@Coitem__FirstOfCoLine Flag
,@Coitem__FirstOfCoNum Flag
,@Coitem__FirstOfCoRelease Flag
,@Coitem__LastOfCoLine Flag
,@Coitem__LastOfCoNum Flag
,@Coitem__LastOfCoRelease Flag
,@CoitemCoLine CoLineType
,@CoitemCoNum CoNumType
,@CoitemCoRelease CoReleaseType
,@CoitemItem ItemType
,@CoitemQtyOrdered QtyUnitNoNegType
,@CoitemQtyReady QtyUnitNoNegType
,@CoitemQtyShipped QtyUnitNoNegType
,@CoitemRefType RefTypeIJKPRTType
,@CoitemRowpointer RowPointerType
,@CoitemStat CoitemStatusType
,@CoitemUM UMType
,@CoitemWhse WhseType
,@CoCustNum CustNumType
,@CoType CoTypeType
,@CoRowpointer RowPointerType
,@LotLocRowpointer RowPointerType
,@LotLocItem ItemType
,@LotLocLoc LocType
,@LotLocLot LotType
,@LotLocQtyOnHand QtyUnitType
,@LotLocQtyRsvd QtyUnitType
,@LotLocWhse WhseType
,@TtShipRowpointer RowPointerType
,@TtShipCoNum CoNumType
,@TtShipCoLine CoLineType
,@TtShipCoRelease CoReleaseType
,@TtShipSequence integer
,@TtShipLoc LocType
,@TtShipLot LotType
,@TtShipUM UMType
,@TtShipTcQtcToShip QtyUnitType
,@TtShipTcQtcToShipConv QtyUnitType
,@TtShipShipStat nchar(1)
,@ItemRowpointer RowPointerType
,@ItemLotTracked ListYesNoType
,@ItemIssueBy ListLocLotType
,@TtShipQtyToShip  QtyUnitType
,@TtShipFirstSequence integer

declare @tt_ship table (
   co_num              CoNumType,
   co_line             CoLineType,
   co_release          CoReleaseType,
   cr_return           bit DEFAULT 0,
   rtn_to_stk          bit DEFAULT 1,
   loc                 LocType,
   lot                 LotType,
   tc_qtc_to_ship      QtyUnitType,
   tc_qtc_to_ship_conv QtyUnitType,
   u_m                 UMType,
   ship_stat           nchar(1),
   by_cons             bit DEFAULT 0,
   sequence            integer,
   reason_code         ReasonCodeType,
   do_num              DoNumType,
   do_line             DoLineType,
   do_selected         bit DEFAULT 0,
   RowPointer RowPointerType DEFAULT newid(),
   PRIMARY KEY (co_num, co_line, co_release, sequence)
   )

declare @w_itemloc table (
   item ItemType,
   loc LocType,
   lot LotType NULL,
   qty_on_hand QtyUnitType,
   RowPointer RowPointerType DEFAULT newid()
   )

select
 @CoCustNum = co.cust_num
,@CoType = co.type
,@CoRowpointer = co.rowpointer
FROM co WITH (READUNCOMMITTED) WHERE co.co_num = @CoNum

declare coitem_crs cursor local static for
select
 coitem.co_line
,coitem.co_num
,coitem.co_release
,coitem.item
,coitem.qty_ordered
,coitem.qty_ready
,coitem.qty_shipped
,coitem.ref_type
,coitem.rowpointer
,coitem.stat
,coitem.u_m
,coitem.whse
from coitem
WHERE coitem.co_num = @CoNum
AND charindex(coitem.stat, @CoitemStatuses) > 0
AND coitem.due_date BETWEEN @StartDate AND @EndDate
AND coitem.whse = @CurWhse
AND coitem.ship_site = @Site
order by coitem.co_num,coitem.due_date, coitem.co_line, coitem.co_release

open coitem_crs
fetch coitem_crs into
 @__LookAheadCoitemCoLine
,@__LookAheadCoitemCoNum
,@__LookAheadCoitemCoRelease
,@__LookAheadCoitemItem
,@__LookAheadCoitemQtyOrdered
,@__LookAheadCoitemQtyReady
,@__LookAheadCoitemQtyShipped
,@__LookAheadCoitemRefType
,@__LookAheadCoitemRowpointer
,@__LookAheadCoitemStat
,@__LookAheadCoitemUM
,@__LookAheadCoitemWhse
set @__LookAheadCoitem__Eof = case when @@fetch_status = 0 then 0 else 1 end
set @Coitem__LastOfCoNum = 1
set @Coitem__LastOfCoLine = 1
set @Coitem__LastOfCoRelease = 1
while 1 = 1
begin
   if @__LookAheadCoitem__Eof <> 0
      break
   set @Coitem__FirstOfCoNum = @Coitem__LastOfCoNum
   set @Coitem__FirstOfCoLine = @Coitem__LastOfCoLine
   set @Coitem__FirstOfCoRelease = @Coitem__LastOfCoRelease
   select
    @CoitemCoLine = @__LookAheadCoitemCoLine
   ,@CoitemCoNum = @__LookAheadCoitemCoNum
   ,@CoitemCoRelease = @__LookAheadCoitemCoRelease
   ,@CoitemItem = @__LookAheadCoitemItem
   ,@CoitemQtyOrdered = @__LookAheadCoitemQtyOrdered
   ,@CoitemQtyReady = @__LookAheadCoitemQtyReady
   ,@CoitemQtyShipped = @__LookAheadCoitemQtyShipped
   ,@CoitemRefType = @__LookAheadCoitemRefType
   ,@CoitemRowpointer = @__LookAheadCoitemRowpointer
   ,@CoitemStat = @__LookAheadCoitemStat
   ,@CoitemUM = @__LookAheadCoitemUM
   ,@CoitemWhse = @__LookAheadCoitemWhse
   
    --RS6252 Set @QtyRemaining = coitem.qty_ordered – coitem.qty_shipped – @QtyToShipInPPS - @QtyPickedInPPS - @QtyPickedInPPS at the first time.
   DECLARE @QtyRemaining QtyUnitType
   , @QtyToShipInPPS QtyPerType
   , @QtyPickedInPPS QtyPerType
   , @QtyToPickInPPS QtyPerType
   
   SET @QtyToShipInPPS = 0
   SET @QtyPickedInPPS = 0
   SET @QtyToPickInPPS = 0
      
   SELECT TOP 1
         @QtyToShipInPPS = SUM(ISNULL(shipseq.qty_picked,0) - ISNULL(shipseq.qty_shipped, 0))
   FROM shipment_seq shipseq
   JOIN shipment_line shipline ON shipline.shipment_id = shipseq.shipment_id AND shipline.shipment_line = shipseq.shipment_line
   JOIN pick_list_ref picklistref ON picklistref.pick_list_id = shipline.pick_list_id AND picklistref.sequence = shipline.pick_list_ref_sequence
   JOIN coitem coitem ON coitem.co_num = picklistref.ref_num AND coitem.co_line = picklistref.ref_line_suf AND coitem.co_release = picklistref.ref_release AND picklistref.ref_type = 'O'
   JOIN shipment ship ON ship.shipment_id = shipseq.shipment_id AND ship.status <> 'S'
   WHERE coitem.co_line = @__LookAheadCoitemCoLine
      AND coitem.co_release = @__LookAheadCoitemCoRelease
      AND coitem.co_num  =@__LookAheadCoitemCoNum


   SELECT TOP 1
         @QtyPickedInPPS = SUM(ISNULL(picklistref.qty_picked,0))
   FROM pick_list_ref picklistref 
   JOIN pick_list picklist ON picklist.pick_list_id = picklistref.pick_list_id
   WHERE picklistref.ref_line_suf = @__LookAheadCoitemCoLine
      AND picklistref.ref_release = @__LookAheadCoitemCoRelease
      AND picklistref.ref_num  =@__LookAheadCoitemCoNum
      AND picklist.status = 'P'
      
   SELECT TOP 1
         @QtyToPickInPPS = SUM(ISNULL(picklistref.qty_to_pick,0))
   FROM pick_list_ref picklistref
   JOIN pick_list picklist ON picklist.pick_list_id = picklistref.pick_list_id
   WHERE picklistref.ref_line_suf = @__LookAheadCoitemCoLine
      AND picklistref.ref_release = @__LookAheadCoitemCoRelease
      AND picklistref.ref_num  =@__LookAheadCoitemCoNum
      AND picklist.status = 'O'
   
   
   fetch coitem_crs into
    @__LookAheadCoitemCoLine
   ,@__LookAheadCoitemCoNum
   ,@__LookAheadCoitemCoRelease
   ,@__LookAheadCoitemItem
   ,@__LookAheadCoitemQtyOrdered
   ,@__LookAheadCoitemQtyReady
   ,@__LookAheadCoitemQtyShipped
   ,@__LookAheadCoitemRefType
   ,@__LookAheadCoitemRowpointer
   ,@__LookAheadCoitemStat
   ,@__LookAheadCoitemUM
   ,@__LookAheadCoitemWhse
   set @__LookAheadCoitem__Eof = case when @@fetch_status = 0 then 0 else 1 end
   set @Coitem__LastOfCoNum = case when @__LookAheadCoitem__Eof = 0 and isnull(nullif(@CoitemCoNum,@__LookAheadCoitemCoNum),nullif(@__LookAheadCoitemCoNum,@CoitemCoNum)) is null then 0 else 1 end
   set @Coitem__LastOfCoLine = case when @Coitem__LastOfCoNum = 0 and isnull(nullif(@CoitemCoLine,@__LookAheadCoitemCoLine),nullif(@__LookAheadCoitemCoLine,@CoitemCoLine)) is null then 0 else 1 end
   set @Coitem__LastOfCoRelease = case when @Coitem__LastOfCoLine = 0 and isnull(nullif(@CoitemCoRelease,@__LookAheadCoitemCoRelease),nullif(@__LookAheadCoitemCoRelease,@CoitemCoRelease)) is null then 0 else 1 end

   DECLARE @NextSequence integer
   IF (@Coitem__FirstOfCoRelease <> 0)
      SET @NextSequence = 1

   DECLARE @UomConvFactor UMConvFactorType
   SET @UomConvFactor = dbo.Getumcf(
      @CoitemUM,
      @CoitemItem,
      @CoCustNum,
      'C'
      )
   DECLARE @FirstItemloc bit
   SET @FirstItemloc = 1
   
  
   
   
   SET @QtyRemaining = dbo.MaxQty(0.0, @CoitemQtyOrdered - @CoitemQtyShipped - ISNULL(@QtyToShipInPPS,0) - ISNULL(@QtyPickedInPPS,0) - ISNULL(@QtyToPickInPPS,0))
   

   select
    @ItemRowpointer = item.rowpointer
   ,@ItemLotTracked = item.lot_tracked
   ,@ItemIssueBy = item.issue_by
   from item WITH (READUNCOMMITTED)
       WHERE item.item = @CoitemItem
   if @@rowcount <> 1
      set @ItemRowpointer = null

   if @ItemRowpointer is null
   begin
      select top 1
       @TtShipRowpointer = tt_ship.rowpointer
      ,@TtShipSequence = tt_ship.sequence
      from @tt_ship as tt_ship
      WHERE tt_ship.co_num = @CoitemCoNum
      AND tt_ship.co_line = @CoitemCoLine
      AND tt_ship.co_release = @CoitemCoRelease
      order by tt_ship.sequence asc
      if @@rowcount <> 1
         set @TtShipRowpointer = null

      IF @TtShipRowpointer is null
      BEGIN
         set @TtShipRowpointer = newid()
         SET @TtShipSequence = @NextSequence
         SET @NextSequence = @NextSequence + 1

         SET @TtShipLoc = NULL
         SET @TtShipLot = NULL
         SET @TtShipTcQtcToShip = @QtyRemaining
         SET @TtShipQtyToShip = @TtShipTcQtcToShip

         SET @TtShipShipStat =
            CASE WHEN @CoitemQtyShipped = 0.0 THEN 'O'  /* Ordered */
            WHEN @CoitemQtyShipped >= @CoitemQtyOrdered THEN 'F'  /* Filled */
            ELSE 'P' /* Partially Shipped */
            END

         insert into @tt_ship (rowpointer, co_num, co_line, co_release, sequence, loc, lot, tc_qtc_to_ship, tc_qtc_to_ship_conv, u_m, ship_stat)
         values(@TtShipRowpointer, @CoitemCoNum, @CoitemCoLine, @CoitemCoRelease, @TtShipSequence, @TtShipLoc, @TtShipLot, @TtShipQtyToShip,@TtShipTcQtcToShip, @CoitemUM, @TtShipShipStat)
      END
      continue
   end

   declare rsvd_inv_crs cursor local static for
   select
    rsvd_inv.ref_num
   ,rsvd_inv.ref_line
   ,rsvd_inv.ref_release
   ,rsvd_inv.loc
   ,rsvd_inv.lot
   ,rsvd_inv.qty_rsvd
   from rsvd_inv
   LEFT JOIN pick_list_ref picklistref 
      ON  picklistref.ref_line_suf = rsvd_inv.ref_line
      AND picklistref.ref_release = rsvd_inv.ref_release
      AND picklistref.ref_num  = rsvd_inv.ref_num
      AND rsvd_inv.qty_rsvd = picklistref.qty_picked     
   WHERE rsvd_inv.ref_num = @CoitemCoNum
   AND rsvd_inv.ref_line = @CoitemCoLine
   AND rsvd_inv.ref_release = @CoitemCoRelease
   AND rsvd_inv.whse = @CoitemWhse
   AND rsvd_inv.qty_rsvd > 0
   AND picklistref.RowPointer is NULL

   open rsvd_inv_crs
   while 1 = 1
   begin
      fetch rsvd_inv_crs into
       @RsvdInvRefNum
      ,@RsvdInvRefLine
      ,@RsvdInvRefRelease
      ,@RsvdInvLoc
      ,@RsvdInvLot
      ,@RsvdInvQtyRsvd
      if @@fetch_status <> 0
         break

      set @TtShipRowpointer = newid()

      SET @FirstItemloc = 0
      SET @TtShipCoNum = @RsvdInvRefNum
      SET @TtShipCoLine = @RsvdInvRefLine
      SET @TtShipCoRelease = @RsvdInvRefRelease
      SET @TtShipSequence = @NextSequence
      SET @NextSequence = @NextSequence + 1

      SET @TtShipLoc = @RsvdInvLoc
      SET @TtShipLot = @RsvdInvLot
      SET @TtShipUM = @CoitemUM
      SET @TtShipTcQtcToShip = dbo.MaxQty(0.0, dbo.MinQty(@RsvdInvQtyRsvd, @QtyRemaining))

      SET @TtShipTcQtcToShipConv = dbo.uomconvqty(@TtShipTcQtcToShip, @UomConvFactor, 'From Base')
      SET @QtyRemaining = @QtyRemaining - @TtShipTcQtcToShip

      SET @TtShipShipStat =
         CASE WHEN @CoitemQtyShipped = 0.0 THEN 'O'  /* Ordered */
         WHEN @CoitemQtyShipped >= @CoitemQtyOrdered THEN 'F'  /* Filled */
         ELSE 'P' /* Partially Shipped */
         END

      insert into @tt_ship (rowpointer, co_num, co_line, co_release, sequence, loc, lot, u_m, tc_qtc_to_ship, tc_qtc_to_ship_conv, ship_stat)
      values(@TtShipRowpointer, @TtShipCoNum, @TtShipCoLine, @TtShipCoRelease, @TtShipSequence, @TtShipLoc, @TtShipLot, @TtShipUM, @TtShipTcQtcToShip, @TtShipTcQtcToShipConv, @TtShipShipStat)
   end
   close rsvd_inv_crs
   deallocate rsvd_inv_crs

   /* if it looks like they are trying to return a lot-tracked item */
   /* When the order line qty remaining is zero, Order Shipping form should still show the order line with zero quantity */
   /* Otherwise, partially shipped order with PPS hold qty cannot be seen and do return process */
   if (@CoitemStat = 'F' OR @CoitemStat = 'O') and @ItemLotTracked <> 0 and @QtyRemaining = 0
   BEGIN
      select top 1
       @ItemlocRowpointer = itemloc.rowpointer
      ,@ItemlocItem = itemloc.item
      ,@ItemlocLoc = itemloc.loc
      ,@ItemlocQtyOnHand = itemloc.qty_on_hand - itemloc.qty_contained
      ,@ItemlocQtyRsvd = itemloc.qty_rsvd
      ,@ItemlocWhse = itemloc.whse
      ,@ItemlocRank = itemloc.rank
      from itemloc
      WHERE itemloc.whse = @CoitemWhse
      AND itemloc.item = @CoitemItem
      AND itemloc.loc_type = 'S'
      AND itemloc.mrb_flag = 0
      order by itemloc.whse asc, itemloc.item asc, itemloc.rank asc
      if @@rowcount <> 1
         set @ItemlocRowpointer = null

      IF (@ItemlocRowpointer is not null)
      BEGIN
         select top 1
          @WItemlocRowpointer = w_itemloc.rowpointer
         ,@WItemlocItem = w_itemloc.item
         ,@WItemlocLoc = w_itemloc.loc
         ,@WItemlocLot = w_itemloc.lot
         ,@WItemlocQtyOnHand = w_itemloc.qty_on_hand
         from @w_itemloc as w_itemloc
         WHERE w_itemloc.item = @ItemlocItem
         AND w_itemloc.loc = @ItemlocLoc
         order by w_itemloc.item asc, w_itemloc.loc asc, w_itemloc.lot asc
         if @@rowcount <> 1
            set @WItemlocRowpointer = null

         IF @WItemlocRowpointer is null
         BEGIN
            set @WItemlocRowpointer = newid()
            SET @WItemlocItem = @ItemlocItem
            SET @WItemlocLoc = @ItemlocLoc
            SET @WItemlocLot = NULL
            SET @WItemlocQtyOnHand = @ItemlocQtyOnHand - @ItemlocQtyRsvd
            insert into @w_itemloc (rowpointer, item, loc, lot, qty_on_hand)
            values(@WItemlocRowpointer, @WItemlocItem, @WItemlocLoc, @WItemlocLot, @WItemlocQtyOnHand)
         END

         select top 1
          @TtShipRowpointer = tt_ship.rowpointer
         ,@TtShipCoNum = tt_ship.co_num
         ,@TtShipCoLine = tt_ship.co_line
         ,@TtShipCoRelease = tt_ship.co_release
         ,@TtShipSequence = tt_ship.sequence
         ,@TtShipLoc = tt_ship.loc
         ,@TtShipLot = tt_ship.lot
         ,@TtShipUM = tt_ship.u_m
         ,@TtShipTcQtcToShip = tt_ship.tc_qtc_to_ship
         ,@TtShipTcQtcToShipConv = tt_ship.tc_qtc_to_ship_conv
         ,@TtShipShipStat = tt_ship.ship_stat
         from @tt_ship as tt_ship
         WHERE tt_ship.co_num = @CoitemCoNum
         AND tt_ship.co_line = @CoitemCoLine
         AND tt_ship.co_release = @CoitemCoRelease
         AND tt_ship.loc = @ItemlocLoc
         order by tt_ship.sequence asc
         if @@rowcount <> 1
            set @TtShipRowpointer = null

         IF @TtShipRowpointer is null
         BEGIN
            set @TtShipRowpointer = newid()
            SET @TtShipCoNum = @CoitemCoNum
            SET @TtShipCoLine = @CoitemCoLine
            SET @TtShipCoRelease = @CoitemCoRelease
            SET @TtShipSequence = @NextSequence
            SET @NextSequence = @NextSequence + 1

            SET @TtShipLoc = @ItemlocLoc
            SET @TtShipLot = NULL
            SET @TtShipTcQtcToShip = dbo.MaxQty(0.0, dbo.MinQty(@WItemlocQtyOnHand, @QtyRemaining))
            SET @TtShipUM = @CoitemUM

            IF @CoitemRefType <> 'I'
               SET @TtShipQtyToShip = dbo.MinQty(@TtShipTcQtcToShip, @CoitemQtyReady)
            ELSE
               SET @TtShipQtyToShip = @TtShipTcQtcToShip

            SET @TtShipShipStat =
               CASE WHEN @CoitemQtyShipped = 0.0 THEN 'O'  /* Ordered */
               WHEN @CoitemQtyShipped >= @CoitemQtyOrdered THEN 'F'  /* Filled */
               ELSE 'P' /* Partially Shipped */
               END

            insert into @tt_ship (rowpointer, co_num, co_line, co_release, sequence, loc, lot, tc_qtc_to_ship, u_m, ship_stat)
            values(@TtShipRowpointer, @TtShipCoNum, @TtShipCoLine, @TtShipCoRelease, @TtShipSequence, @TtShipLoc, @TtShipLot, @TtShipQtyToShip, @TtShipUM, @TtShipShipStat)
         END
         ELSE
         BEGIN
            SET @TtShipTcQtcToShip = dbo.MaxQty(0.0, @TtShipTcQtcToShip
               + dbo.MinQty(dbo.MaxQty(0.0, @WItemlocQtyOnHand), @QtyRemaining))
            SET @TtShipQtyToShip = @TtShipTcQtcToShip
         END

         SET @TtShipTcQtcToShipConv = dbo.uomconvqty(@TtShipQtyToShip,
            @UomConvFactor,
            'From Base')
         update @tt_ship
         set
          tc_qtc_to_ship = @TtShipQtyToShip
         ,tc_qtc_to_ship_conv = @TtShipTcQtcToShipConv
         where rowpointer = @TtShipRowpointer

         SET @QtyRemaining = @QtyRemaining - @TtShipTcQtcToShip
         SET @WItemlocQtyOnHand = @WItemlocQtyOnHand - @TtShipTcQtcToShip
         update @w_itemloc
         set qty_on_hand = @WItemlocQtyOnHand
         where rowpointer = @WItemlocRowpointer
      END

      CONTINUE
   end

   IF @ItemLotTracked <> 0 AND @ItemIssueBy = 'lot'
   BEGIN
      if not EXISTS(SELECT 1 FROM
        lot_loc INNER JOIN itemloc  ON
        lot_loc.whse= itemloc.whse
        AND lot_loc.item = itemloc.item
        AND lot_loc.loc = itemloc.loc
        WHERE lot_loc.whse = @CoitemWhse
        AND lot_loc.item = @CoitemItem
        AND lot_loc.qty_on_hand - lot_loc.qty_contained > 0.0
        AND itemloc.mrb_flag = 0)
      BEGIN
         select top 1
          @LotLocRowpointer = lot_loc.rowpointer
         ,@LotLocItem = lot_loc.item
         ,@LotLocLoc = lot_loc.loc
         ,@LotLocLot = lot_loc.lot
         ,@LotLocQtyOnHand = lot_loc.qty_on_hand - lot_loc.qty_contained
         ,@LotLocQtyRsvd = lot_loc.qty_rsvd
         ,@LotLocWhse = lot_loc.whse
         from lot_loc
         WHERE lot_loc.whse = @CoitemWhse
         AND lot_loc.item = @CoitemItem
         order by lot_loc.whse asc, lot_loc.item asc, lot_loc.lot asc, lot_loc.loc asc
         if @@rowcount <> 1
            set @LotLocRowpointer = null

         IF (@LotLocRowpointer is not null)
         BEGIN
            select top 1
             @WItemlocRowpointer = w_itemloc.rowpointer
            ,@WItemlocItem = w_itemloc.item
            ,@WItemlocLoc = w_itemloc.loc
            ,@WItemlocLot = w_itemloc.lot
            ,@WItemlocQtyOnHand = w_itemloc.qty_on_hand
            from @w_itemloc as w_itemloc
            WHERE w_itemloc.item = @LotLocItem
            AND w_itemloc.loc = @LotLocLoc
            AND w_itemloc.lot = @LotLocLot
            order by w_itemloc.item asc, w_itemloc.loc asc, w_itemloc.lot asc
            if @@rowcount <> 1
               set @WItemlocRowpointer = null

            IF @WItemlocRowpointer is null
            BEGIN
               set @WItemlocRowpointer = newid()
               SET @WItemlocItem = @LotLocItem
               SET @WItemlocLoc = @LotLocLoc
               SET @WItemlocLot = @LotLocLot
               SET @WItemlocQtyOnHand = @LotLocQtyOnHand - @LotLocQtyRsvd
               insert into @w_itemloc (rowpointer, item, loc, lot, qty_on_hand)
               values(@WItemlocRowpointer, @WItemlocItem, @WItemlocLoc, @WItemlocLot, @WItemlocQtyOnHand)
            END

            select top 1
             @TtShipRowpointer = tt_ship.rowpointer
            ,@TtShipCoNum = tt_ship.co_num
            ,@TtShipCoLine = tt_ship.co_line
            ,@TtShipCoRelease = tt_ship.co_release
            ,@TtShipSequence = tt_ship.sequence
            ,@TtShipLoc = tt_ship.loc
            ,@TtShipLot = tt_ship.lot
            ,@TtShipUM = tt_ship.u_m
            ,@TtShipTcQtcToShip = tt_ship.tc_qtc_to_ship
            ,@TtShipTcQtcToShipConv = tt_ship.tc_qtc_to_ship_conv
            ,@TtShipShipStat = tt_ship.ship_stat
            from @tt_ship as tt_ship
            WHERE tt_ship.co_num = @CoitemCoNum
            AND tt_ship.co_line = @CoitemCoLine
            AND tt_ship.co_release = @CoitemCoRelease
            AND tt_ship.loc = @LotLocLoc
            AND tt_ship.lot = @LotLocLot
            order by tt_ship.sequence asc
            if @@rowcount <> 1
               set @TtShipRowpointer = null

            IF @TtShipRowpointer is null
            BEGIN
               set @TtShipRowpointer = newid()
               SET @TtShipCoNum = @CoitemCoNum
               SET @TtShipCoLine = @CoitemCoLine
               SET @TtShipCoRelease = @CoitemCoRelease
               SET @TtShipSequence = @NextSequence
               SET @NextSequence = @NextSequence + 1

               SET @TtShipLoc = @LotLocLoc
               SET @TtShipLot = @LotLocLot
               SET @TtShipTcQtcToShip = dbo.MaxQty(0.0, dbo.MinQty(@WItemlocQtyOnHand, @QtyRemaining))
               SET @TtShipUM = @CoitemUM

               IF @CoitemRefType <> 'I'
                  SET @TtShipQtyToShip = dbo.MinQty(@TtShipTcQtcToShip, @CoitemQtyReady)
               ELSE
                  SET @TtShipQtyToShip = @TtShipTcQtcToShip

               SET @TtShipShipStat =
                  CASE WHEN @CoitemQtyShipped = 0.0 THEN 'O'  /* Ordered */
                  WHEN @CoitemQtyShipped >= @CoitemQtyOrdered THEN 'F'  /* Filled */
                  ELSE 'P' /* Partially Shipped */
                  END

               insert into @tt_ship (rowpointer, co_num, co_line, co_release, sequence, loc, lot, tc_qtc_to_ship, u_m, ship_stat)
               values(@TtShipRowpointer, @TtShipCoNum, @TtShipCoLine, @TtShipCoRelease, @TtShipSequence, @TtShipLoc, @TtShipLot, @TtShipQtyToShip, @TtShipUM, @TtShipShipStat)
            END
            ELSE
            BEGIN
               SET @TtShipTcQtcToShip = dbo.MaxQty(0.0, @TtShipTcQtcToShip
                  + dbo.MinQty(dbo.MaxQty(0.0, @WItemlocQtyOnHand), @QtyRemaining))
               SET @TtShipQtyToShip = @TtShipTcQtcToShip
            END

            SET @TtShipTcQtcToShipConv = dbo.uomconvqty(@TtShipQtyToShip,
               @UomConvFactor,
               'From Base')
            update @tt_ship
            set
             tc_qtc_to_ship = @TtShipQtyToShip
            ,tc_qtc_to_ship_conv = @TtShipTcQtcToShipConv
            where rowpointer = @TtShipRowpointer

            SET @QtyRemaining = @QtyRemaining - @TtShipTcQtcToShip
            SET @WItemlocQtyOnHand = @WItemlocQtyOnHand - @TtShipTcQtcToShip
            update @w_itemloc
            set
             qty_on_hand = @WItemlocQtyOnHand
            where rowpointer = @WItemlocRowpointer
         END
         ELSE
         BEGIN
            select top 1
             @WItemlocRowpointer = w_itemloc.rowpointer
            ,@WItemlocItem = w_itemloc.item
            ,@WItemlocLoc = w_itemloc.loc
            ,@WItemlocLot = w_itemloc.lot
            ,@WItemlocQtyOnHand = w_itemloc.qty_on_hand
            from @w_itemloc as w_itemloc
            WHERE w_itemloc.item = @CoitemItem
            AND w_itemloc.loc IS NULL
            AND w_itemloc.lot IS NULL
            order by w_itemloc.item asc, w_itemloc.loc asc, w_itemloc.lot asc
            if @@rowcount <> 1
               set @WItemlocRowpointer = null

            IF @WItemlocRowpointer is null
            BEGIN
               set @WItemlocRowpointer = newid()
               SET @WItemlocItem = @CoitemItem
               SET @WItemlocLoc = NULL
               SET @WItemlocLot = NULL
               SET @WItemlocQtyOnHand = 0
               insert into @w_itemloc (rowpointer, item, loc, lot, qty_on_hand)
               values(@WItemlocRowpointer, @WItemlocItem, @WItemlocLoc, @WItemlocLot, @WItemlocQtyOnHand)
            END

            select top 1
             @TtShipRowpointer = tt_ship.rowpointer
            ,@TtShipCoNum = tt_ship.co_num
            ,@TtShipCoLine = tt_ship.co_line
            ,@TtShipCoRelease = tt_ship.co_release
            ,@TtShipSequence = tt_ship.sequence
            ,@TtShipLoc = tt_ship.loc
            ,@TtShipLot = tt_ship.lot
            ,@TtShipUM = tt_ship.u_m
            ,@TtShipTcQtcToShip = tt_ship.tc_qtc_to_ship
            ,@TtShipTcQtcToShipConv = tt_ship.tc_qtc_to_ship_conv
            ,@TtShipShipStat = tt_ship.ship_stat
            from @tt_ship as tt_ship
            WHERE tt_ship.co_num = @CoitemCoNum
            AND tt_ship.co_line = @CoitemCoLine
            AND tt_ship.co_release = @CoitemCoRelease
            AND tt_ship.loc IS NULL
            AND tt_ship.lot IS NULL
            order by tt_ship.sequence asc
            if @@rowcount <> 1
               set @TtShipRowpointer = null

            IF @TtShipRowpointer is null
            BEGIN
               set @TtShipRowpointer = newid()
               SET @TtShipCoNum = @CoitemCoNum
               SET @TtShipCoLine = @CoitemCoLine
               SET @TtShipCoRelease = @CoitemCoRelease
               SET @TtShipSequence = @NextSequence
               SET @NextSequence = @NextSequence + 1

               SET @TtShipLoc = NULL
               SET @TtShipLot = NULL
               SET @TtShipTcQtcToShip = dbo.MaxQty(0.0, dbo.MinQty(@WItemlocQtyOnHand, @QtyRemaining))
               SET @TtShipUM = @CoitemUM

               IF @CoitemRefType <> 'I'
                  SET @TtShipQtyToShip = dbo.MinQty(@TtShipTcQtcToShip, @CoitemQtyReady)
               ELSE
                  SET @TtShipQtyToShip = @TtShipTcQtcToShip

               SET @TtShipShipStat =
                  CASE WHEN @CoitemQtyShipped = 0.0 THEN 'O'  /* Ordered */
                  WHEN @CoitemQtyShipped >= @CoitemQtyOrdered THEN 'F'  /* Filled */
                  ELSE 'P' /* Partially Shipped */
                  END

               insert into @tt_ship (rowpointer, co_num, co_line, co_release, sequence, loc, lot, tc_qtc_to_ship, u_m, ship_stat)
               values(@TtShipRowpointer, @TtShipCoNum, @TtShipCoLine, @TtShipCoRelease, @TtShipSequence, @TtShipLoc, @TtShipLot, @TtShipQtyToShip, @TtShipUM, @TtShipShipStat)
            END
            ELSE
            BEGIN
               SET @TtShipTcQtcToShip = dbo.MaxQty(0.0, @TtShipTcQtcToShip
                  + dbo.MinQty(dbo.MaxQty(0.0, @WItemlocQtyOnHand), @QtyRemaining))
               SET @TtShipQtyToShip = @TtShipTcQtcToShip
            END

            SET @TtShipTcQtcToShipConv = dbo.uomconvqty(@TtShipQtyToShip,
               @UomConvFactor,
               'From Base')
            update @tt_ship
            set
             tc_qtc_to_ship = @TtShipQtyToShip
            ,tc_qtc_to_ship_conv = @TtShipTcQtcToShipConv
            where rowpointer = @TtShipRowpointer

            SET @QtyRemaining = @QtyRemaining - @TtShipTcQtcToShip
            SET @WItemlocQtyOnHand = @WItemlocQtyOnHand - @TtShipTcQtcToShip
            update @w_itemloc
            set
             qty_on_hand = @WItemlocQtyOnHand
            where rowpointer = @WItemlocRowpointer
         END
      END /* lot-loc w/qty > 0 not available */
      /* lot-loc w/qty > 0 available */
      ELSE
      BEGIN
         declare lot_loc_itemloc_crs cursor local static for
         select
          lot_loc.rowpointer
         ,lot_loc.item
         ,lot_loc.loc
         ,lot_loc.lot
         ,lot_loc.qty_on_hand - lot_loc.qty_contained
         ,lot_loc.qty_rsvd
         ,lot_loc.whse,
          itemloc.rowpointer
         ,itemloc.item
         ,itemloc.loc
         ,itemloc.qty_on_hand - itemloc.qty_contained
         ,itemloc.qty_rsvd
         ,itemloc.whse
         ,itemloc.rank
         from lot_loc
         INNER JOIN itemloc
         ON itemloc.whse = lot_loc.whse
         AND itemloc.item = lot_loc.item
         AND itemloc.loc = lot_loc.loc
         WHERE lot_loc.whse = @CoitemWhse
         AND lot_loc.item = @CoitemItem
         AND lot_loc.qty_on_hand - lot_loc.qty_contained > 0.0
         AND itemloc.loc_type = 'S'
         AND itemloc.mrb_flag = 0
         ORDER BY lot_loc.lot, itemloc.rank

         open lot_loc_itemloc_crs
         while 1 = 1
         begin
            fetch lot_loc_itemloc_crs into
             @LotLocRowpointer
            ,@LotLocItem
            ,@LotLocLoc
            ,@LotLocLot
            ,@LotLocQtyOnHand
            ,@LotLocQtyRsvd
            ,@LotLocWhse   ,
             @ItemlocRowpointer
            ,@ItemlocItem
            ,@ItemlocLoc
            ,@ItemlocQtyOnHand
            ,@ItemlocQtyRsvd
            ,@ItemlocWhse
            ,@ItemlocRank
            if @@fetch_status <> 0
               break

            if @QtyRemaining <= 0.0
               BREAK

            IF @CoitemQtyReady = 0 and @CoitemRefType <> 'I'
            begin
               select top 1
                @WItemlocRowpointer = w_itemloc.rowpointer
               ,@WItemlocItem = w_itemloc.item
               ,@WItemlocLoc = w_itemloc.loc
               ,@WItemlocLot = w_itemloc.lot
               ,@WItemlocQtyOnHand = w_itemloc.qty_on_hand
               from @w_itemloc as w_itemloc
               WHERE w_itemloc.item = @LotLocItem
               AND w_itemloc.loc = @LotLocLoc
               AND w_itemloc.lot IS NULL
               order by w_itemloc.item asc, w_itemloc.loc asc, w_itemloc.lot asc
               if @@rowcount <> 1
                  set @WItemlocRowpointer = null
            end
            ELSE
            begin
               select top 1
                @WItemlocRowpointer = w_itemloc.rowpointer
               ,@WItemlocItem = w_itemloc.item
               ,@WItemlocLoc = w_itemloc.loc
               ,@WItemlocLot = w_itemloc.lot
               ,@WItemlocQtyOnHand = w_itemloc.qty_on_hand
               from @w_itemloc as w_itemloc
               WHERE w_itemloc.item = @LotLocItem
               AND w_itemloc.loc = @LotLocLoc
               AND w_itemloc.lot = @LotLocLot
               order by w_itemloc.item asc, w_itemloc.loc asc, w_itemloc.lot asc
               if @@rowcount <> 1
                  set @WItemlocRowpointer = null
            end
            IF @WItemlocRowpointer is null
            BEGIN
               set @WItemlocRowpointer = newid()
               SET @WItemlocItem = @LotLocItem
               SET @WItemlocLoc = @LotLocLoc
               SET @WItemlocLot = @LotLocLot
               SET @WItemlocQtyOnHand = @LotLocQtyOnHand - @LotLocQtyRsvd
               insert into @w_itemloc (rowpointer, item, loc, lot, qty_on_hand)
               values(@WItemlocRowpointer, @WItemlocItem, @WItemlocLoc, @WItemlocLot, @WItemlocQtyOnHand)
            END

            IF @CoitemQtyReady = 0 and @CoitemRefType <> 'I'
            begin
               select top 1
                @TtShipRowpointer = tt_ship.rowpointer
               ,@TtShipCoNum = tt_ship.co_num
               ,@TtShipCoLine = tt_ship.co_line
               ,@TtShipCoRelease = tt_ship.co_release
               ,@TtShipSequence = tt_ship.sequence
               ,@TtShipLoc = tt_ship.loc
               ,@TtShipLot = tt_ship.lot
               ,@TtShipUM = tt_ship.u_m
               ,@TtShipTcQtcToShip = tt_ship.tc_qtc_to_ship
               ,@TtShipTcQtcToShipConv = tt_ship.tc_qtc_to_ship_conv
               ,@TtShipShipStat = tt_ship.ship_stat
               from @tt_ship as tt_ship
               WHERE tt_ship.co_num = @CoitemCoNum
               AND tt_ship.co_line = @CoitemCoLine
               AND tt_ship.co_release = @CoitemCoRelease
               AND tt_ship.loc = @LotLocLoc
               AND tt_ship.lot IS NULL
               order by tt_ship.sequence asc
               if @@rowcount <> 1
                  set @TtShipRowpointer = null
            end
            ELSE
            begin
               select top 1
                @TtShipRowpointer = tt_ship.rowpointer
               ,@TtShipCoNum = tt_ship.co_num
               ,@TtShipCoLine = tt_ship.co_line
               ,@TtShipCoRelease = tt_ship.co_release
               ,@TtShipSequence = tt_ship.sequence
               ,@TtShipLoc = tt_ship.loc
               ,@TtShipLot = tt_ship.lot
               ,@TtShipUM = tt_ship.u_m
               ,@TtShipTcQtcToShip = tt_ship.tc_qtc_to_ship
               ,@TtShipTcQtcToShipConv = tt_ship.tc_qtc_to_ship_conv
               ,@TtShipShipStat = tt_ship.ship_stat
               from @tt_ship as tt_ship
               WHERE tt_ship.co_num = @CoitemCoNum
               AND tt_ship.co_line = @CoitemCoLine
               AND tt_ship.co_release = @CoitemCoRelease
               AND tt_ship.loc = @LotLocLoc
               AND tt_ship.lot = @LotLocLot
               order by tt_ship.sequence asc
               if @@rowcount <> 1
                  set @TtShipRowpointer = null
            end
            IF @TtShipRowpointer is null
            BEGIN
               set @TtShipRowpointer = newid()
               SET @TtShipCoNum = @CoitemCoNum
               SET @TtShipCoLine = @CoitemCoLine
               SET @TtShipCoRelease = @CoitemCoRelease
               SET @TtShipSequence = @NextSequence
               SET @NextSequence = @NextSequence + 1

               SET @TtShipLoc = @LotLocLoc
               SET @TtShipLot = CASE WHEN @WItemlocQtyOnHand > 0 THEN @LotLocLot ELSE NULL END
               SET @TtShipTcQtcToShip = dbo.MaxQty(0.0, dbo.MinQty(@WItemlocQtyOnHand, @QtyRemaining))
               SET @TtShipUM = @CoitemUM

               IF @CoitemRefType <> 'I'
                  SET @TtShipQtyToShip = dbo.MinQty(@TtShipTcQtcToShip, @CoitemQtyReady)
               ELSE
                  SET @TtShipQtyToShip = @TtShipTcQtcToShip

               SET @TtShipShipStat =
                  CASE WHEN @CoitemQtyShipped = 0.0 THEN 'O'  /* Ordered */
                  WHEN @CoitemQtyShipped >= @CoitemQtyOrdered THEN 'F'  /* Filled */
                  ELSE 'P' /* Partially Shipped */
                  END
               insert into @tt_ship (rowpointer, co_num, co_line, co_release, sequence, loc, lot, tc_qtc_to_ship, u_m, ship_stat)
               values(@TtShipRowpointer, @TtShipCoNum, @TtShipCoLine, @TtShipCoRelease, @TtShipSequence, @TtShipLoc, @TtShipLot, @TtShipQtyToShip, @TtShipUM, @TtShipShipStat)
            END
            ELSE
            BEGIN
               SET @TtShipTcQtcToShip = dbo.MaxQty(0.0, @TtShipTcQtcToShip
                  + dbo.MinQty(dbo.MaxQty(0.0, @WItemlocQtyOnHand), @QtyRemaining))
               SET @TtShipQtyToShip = @TtShipTcQtcToShip
            END

            SET @TtShipTcQtcToShipConv = dbo.uomconvqty(@TtShipQtyToShip,
               @UomConvFactor,
               'From Base')

            update @tt_ship
            set
             tc_qtc_to_ship = @TtShipQtyToShip
            ,tc_qtc_to_ship_conv = @TtShipTcQtcToShipConv
            where rowpointer = @TtShipRowpointer

            /* Remove rows that have zero qty to ship except at least one row for a CO, CO Line, CO Release combination */
            /* If there is at least one row that has a non-zero qty to ship for a CO, CO Line, CO Release combination
             * delete all other rows that have zero qty to ship */
            IF EXISTS( SELECT TOP 1 1
                       FROM @tt_ship
                       WHERE co_num = @TtShipCoNum
                       AND co_line = @TtShipCoLine
                       AND co_release = @TtShipCoRelease
                       AND tc_qtc_to_ship <> 0 )
            BEGIN
               DELETE FROM @tt_ship
               WHERE co_num = @TtShipCoNum
               AND co_line = @TtShipCoLine
               AND co_release = @TtShipCoRelease
               AND tc_qtc_to_ship = 0
            END
            ELSE
            /* If all rows have zero qty to ship for a CO, CO Line, CO Release combination
             * delete all rows except first one */
            BEGIN
               SET @TtShipFirstSequence = NULL
               SELECT TOP 1 @TtShipFirstSequence = sequence
               FROM @tt_ship
               WHERE co_num = @TtShipCoNum
               AND co_line = @TtShipCoLine
               AND co_release = @TtShipCoRelease
               AND tc_qtc_to_ship = 0
               ORDER BY co_num, co_line, co_release, sequence ASC

               IF @TtShipFirstSequence IS NOT NULL
                  DELETE FROM @tt_ship
                  WHERE co_num = @TtShipCoNum
                  AND co_line = @TtShipCoLine
                  AND co_release = @TtShipCoRelease
                  AND tc_qtc_to_ship = 0
                  AND sequence > @TtShipFirstSequence
            END

            SET @QtyRemaining = @QtyRemaining - @TtShipTcQtcToShip
            SET @WItemlocQtyOnHand = @WItemlocQtyOnHand - @TtShipTcQtcToShip

            update @w_itemloc
            set
             qty_on_hand = @WItemlocQtyOnHand
            where rowpointer = @WItemlocRowpointer

            if @CoitemRefType <> 'I' and @CoitemQtyReady = 0
               BREAK
         end
         close lot_loc_itemloc_crs
         deallocate lot_loc_itemloc_crs
      end
   END /* lot tracked and issuing by lot */
   /* either not lot tracked or issuing by loc */
   ELSE
   WHILE @QtyRemaining > 0.0 OR @FirstItemloc <> 0
   BEGIN
      IF @FirstItemloc <> 0
      BEGIN
         select top 1
          @ItemlocRowpointer = itemloc.rowpointer
         ,@ItemlocItem = itemloc.item
         ,@ItemlocLoc = itemloc.loc
         ,@ItemlocQtyOnHand = itemloc.qty_on_hand - itemloc.qty_contained
         ,@ItemlocQtyRsvd = itemloc.qty_rsvd
         ,@ItemlocWhse = itemloc.whse
         ,@ItemlocRank = itemloc.rank
         from itemloc
         WHERE itemloc.whse = @CoitemWhse
         AND itemloc.item = @CoitemItem
         AND itemloc.loc_type = 'S'
         AND itemloc.qty_on_hand - itemloc.qty_contained > 0.0
         AND itemloc.mrb_flag = 0
         and 1 = case when @ItemLotTracked = 0 then 1
            else case when exists (select 1 from lot_loc where lot_loc.whse = itemloc.whse
               and lot_loc.loc = itemloc.loc
               and lot_loc.item = itemloc.item
               and lot_loc.qty_on_hand - lot_loc.qty_contained > 0) then 1 else 0 end
               end
         order by itemloc.whse asc, itemloc.item asc, itemloc.rank asc
         if @@rowcount <> 1
            set @ItemlocRowpointer = null

         IF @ItemlocRowpointer is null
            /* must create at least one tt-ship record per coitem
             * (in case user wishes to Return or Negative Ship */
         begin
            select top 1
             @ItemlocRowpointer = itemloc.rowpointer
            ,@ItemlocItem = itemloc.item
            ,@ItemlocLoc = itemloc.loc
            ,@ItemlocQtyOnHand = itemloc.qty_on_hand - itemloc.qty_contained
            ,@ItemlocQtyRsvd = itemloc.qty_rsvd
            ,@ItemlocWhse = itemloc.whse
            ,@ItemlocRank = itemloc.rank
            from itemloc
            WHERE itemloc.whse = @CoitemWhse
            AND itemloc.item = @CoitemItem
            AND itemloc.loc_type = 'S'
            AND itemloc.mrb_flag = 0
            and 1 = case when @ItemLotTracked = 0 then 1
               else case when exists (select 1 from lot_loc where lot_loc.whse = itemloc.whse
                  and lot_loc.loc = itemloc.loc
                  and lot_loc.item = itemloc.item
                  and lot_loc.qty_on_hand - lot_loc.qty_contained > 0) then 1 else 0 end
                  end
            order by itemloc.whse asc, itemloc.item asc, itemloc.rank asc
            if @@rowcount <> 1
               set @ItemlocRowpointer = null

            if @ItemlocRowpointer is null and @ItemLotTracked = 1
            begin
               select top 1
                @ItemlocRowpointer = itemloc.rowpointer
               ,@ItemlocItem = itemloc.item
               ,@ItemlocLoc = itemloc.loc
               ,@ItemlocQtyOnHand = itemloc.qty_on_hand - itemloc.qty_contained
               ,@ItemlocQtyRsvd = itemloc.qty_rsvd
               ,@ItemlocWhse = itemloc.whse
               ,@ItemlocRank = itemloc.rank
               from itemloc
                  inner join lot_loc on
                     lot_loc.whse = itemloc.whse
                     and lot_loc.loc = itemloc.loc
                     and lot_loc.item = itemloc.item
                     and lot_loc.qty_on_hand - lot_loc.qty_contained > 0
               WHERE itemloc.whse = @CoitemWhse
               AND itemloc.item = @CoitemItem
               AND itemloc.loc_type = 'S'
               order by itemloc.whse asc, itemloc.item asc, itemloc.rank asc

               if @ItemlocRowpointer is null
                  select top 1
                   @ItemlocRowpointer = itemloc.rowpointer
                  ,@ItemlocItem = itemloc.item
                  ,@ItemlocLoc = itemloc.loc
                  ,@ItemlocQtyOnHand = itemloc.qty_on_hand
                  ,@ItemlocQtyRsvd = itemloc.qty_rsvd
                  ,@ItemlocWhse = itemloc.whse
                  ,@ItemlocRank = itemloc.rank
                  from itemloc
                     inner join lot_loc on
                        lot_loc.whse = itemloc.whse
                        and lot_loc.loc = itemloc.loc
                        and lot_loc.item = itemloc.item
                  WHERE itemloc.whse = @CoitemWhse
                  AND itemloc.item = @CoitemItem
                  AND itemloc.loc_type = 'S'
                  order by itemloc.whse asc, itemloc.item asc, itemloc.rank asc

               if @ItemlocRowpointer is null
                  select top 1
                   @ItemlocRowpointer = itemloc.rowpointer
                  ,@ItemlocItem = itemloc.item
                  ,@ItemlocLoc = itemloc.loc
                  ,@ItemlocQtyOnHand = itemloc.qty_on_hand
                  ,@ItemlocQtyRsvd = itemloc.qty_rsvd
                  ,@ItemlocWhse = itemloc.whse
                  ,@ItemlocRank = itemloc.rank
                  from itemloc
                  WHERE itemloc.whse = @CoitemWhse
                  AND itemloc.item = @CoitemItem
                  AND itemloc.loc_type = 'S'
                  order by itemloc.whse asc, itemloc.item asc, itemloc.rank asc
            end
         end
      END
      ELSE
      begin
         select top 1
          @ItemlocRowpointer = itemloc.rowpointer
         ,@ItemlocItem = itemloc.item
         ,@ItemlocLoc = itemloc.loc
         ,@ItemlocQtyOnHand = itemloc.qty_on_hand - itemloc.qty_contained
         ,@ItemlocQtyRsvd = itemloc.qty_rsvd
         ,@ItemlocWhse = itemloc.whse
         ,@ItemlocRank = itemloc.rank
         from itemloc
            where ( itemloc.whse = @CoitemWhse
            AND itemloc.item = @CoitemItem
            AND itemloc.loc_type = 'S'
            AND itemloc.qty_on_hand - itemloc.qty_contained > 0.0
            AND itemloc.mrb_flag = 0
           ) and (
            (itemloc.whse = @ItemlocWhse
            and itemloc.item = @ItemlocItem
            and itemloc.rank = @ItemlocRank
            and itemloc.rowpointer > @ItemlocRowpointer)
            or (itemloc.whse = @ItemlocWhse
            and itemloc.item = @ItemlocItem
            and itemloc.rank > @ItemlocRank)
            or (itemloc.whse = @ItemlocWhse
            and itemloc.item > @ItemlocItem)
            or (itemloc.whse > @ItemlocWhse))
            order by itemloc.whse asc, itemloc.item asc, itemloc.rank asc
         if @@rowcount <> 1
            set @ItemlocRowpointer = null
      end

      IF @ItemlocRowpointer is null AND @ItemRowpointer IS NOT NULL
         BREAK /* next coitem */
      IF @QtyRemaining <= 0.0 AND @FirstItemloc = 0
         BREAK

      DECLARE @FirstLotLoc bit
      SET @FirstLotLoc = 1

      IF @ItemLotTracked <> 0
         WHILE @QtyRemaining > 0.0
         BEGIN
            IF @FirstLotLoc <> 0
            BEGIN
               select top 1
                @LotLocRowpointer = lot_loc.rowpointer
               ,@LotLocItem = lot_loc.item
               ,@LotLocLoc = lot_loc.loc
               ,@LotLocLot = lot_loc.lot
               ,@LotLocQtyOnHand = lot_loc.qty_on_hand - lot_loc.qty_contained
               ,@LotLocQtyRsvd = lot_loc.qty_rsvd
               ,@LotLocWhse = lot_loc.whse
               from lot_loc
               WHERE lot_loc.whse = @ItemlocWhse
               AND lot_loc.item = @ItemlocItem
               AND lot_loc.loc = @ItemlocLoc
               AND lot_loc.qty_on_hand - lot_loc.qty_contained > 0.0
               order by lot_loc.whse asc, lot_loc.item asc, lot_loc.lot asc, lot_loc.loc asc
               if @@rowcount <> 1
                  set @LotLocRowpointer = null

               IF @LotLocRowpointer is null
               begin
                  select top 1
                   @LotLocRowpointer = lot_loc.rowpointer
                  ,@LotLocItem = lot_loc.item
                  ,@LotLocLoc = lot_loc.loc
                  ,@LotLocLot = lot_loc.lot
                  ,@LotLocQtyOnHand = lot_loc.qty_on_hand - lot_loc.qty_contained
                  ,@LotLocQtyRsvd = lot_loc.qty_rsvd
                  ,@LotLocWhse = lot_loc.whse
                  from lot_loc
                  WHERE lot_loc.whse = @ItemlocWhse
                  AND lot_loc.item = @ItemlocItem
                  AND lot_loc.loc = @ItemlocLoc
                  order by lot_loc.whse asc, lot_loc.item asc, lot_loc.lot asc, lot_loc.loc asc
                  if @@rowcount <> 1
                     set @LotLocRowpointer = null
               end
            END
            ELSE
            begin
               select top 1
                @LotLocRowpointer = lot_loc.rowpointer
               ,@LotLocItem = lot_loc.item
               ,@LotLocLoc = lot_loc.loc
               ,@LotLocLot = lot_loc.lot
               ,@LotLocQtyOnHand = lot_loc.qty_on_hand - lot_loc.qty_contained
               ,@LotLocQtyRsvd = lot_loc.qty_rsvd
               ,@LotLocWhse = lot_loc.whse
               from lot_loc
                  where ( lot_loc.whse = @ItemlocWhse
                  AND lot_loc.item = @ItemlocItem
                  AND lot_loc.loc = @ItemlocLoc
                  AND lot_loc.qty_on_hand - lot_loc.qty_contained > 0.0
                 ) and (
                  (lot_loc.whse = @LotLocWhse
                  and lot_loc.item = @LotLocItem
                  and lot_loc.lot = @LotLocLot
                  and lot_loc.loc = @LotLocLoc
                  and lot_loc.rowpointer > @LotLocRowpointer)
                or (lot_loc.whse = @LotLocWhse
                  and lot_loc.item = @LotLocItem
                  and lot_loc.lot = @LotLocLot
                  and lot_loc.loc > @LotLocLoc)
                or (lot_loc.whse = @LotLocWhse
                  and lot_loc.item = @LotLocItem
                  and lot_loc.lot > @LotLocLot)
                or (lot_loc.whse = @LotLocWhse
                  and lot_loc.item > @LotLocItem)
                or (lot_loc.whse > @LotLocWhse))
               order by lot_loc.whse asc, lot_loc.item asc, lot_loc.lot asc, lot_loc.loc asc
               if @@rowcount <> 1
                  set @LotLocRowpointer = null
            end

            IF @LotLocRowpointer is null and @FirstLotLoc = 0
               BREAK /* next itemloc */

            SET @FirstLotLoc = 0

            IF @CoitemQtyReady = 0 and @CoitemRefType <> 'I'
            begin
               select top 1
                @WItemlocRowpointer = w_itemloc.rowpointer
               ,@WItemlocItem = w_itemloc.item
               ,@WItemlocLoc = w_itemloc.loc
               ,@WItemlocLot = w_itemloc.lot
               ,@WItemlocQtyOnHand = w_itemloc.qty_on_hand
               from @w_itemloc as w_itemloc
               WHERE w_itemloc.item = @LotLocItem
               AND w_itemloc.loc = @LotLocLoc
               AND w_itemloc.lot IS NULL
               order by w_itemloc.item asc, w_itemloc.loc asc, w_itemloc.lot asc
               if @@rowcount <> 1
                  set @WItemlocRowpointer = null
            end
            ELSE
            begin
               select top 1
                @WItemlocRowpointer = w_itemloc.rowpointer
               ,@WItemlocItem = w_itemloc.item
               ,@WItemlocLoc = w_itemloc.loc
               ,@WItemlocLot = w_itemloc.lot
               ,@WItemlocQtyOnHand = w_itemloc.qty_on_hand
               from @w_itemloc as w_itemloc
               WHERE w_itemloc.item = @LotLocItem
               AND w_itemloc.loc = @LotLocLoc
               AND w_itemloc.lot = @LotLocLot
               order by w_itemloc.item asc, w_itemloc.loc asc, w_itemloc.lot asc
               if @@rowcount <> 1
                  set @WItemlocRowpointer = null
            end
            IF @WItemlocRowpointer is null
            BEGIN
               set @WItemlocRowpointer = newid()
               SET @WItemlocItem = @LotLocItem
               SET @WItemlocLoc = @LotLocLoc
               SET @WItemlocLot = @LotLocLot
               SET @WItemlocQtyOnHand = @LotLocQtyOnHand - @LotLocQtyRsvd
               insert into @w_itemloc (rowpointer, item, loc, lot, qty_on_hand)
               values(@WItemlocRowpointer, @WItemlocItem, @WItemlocLoc, @WItemlocLot, @WItemlocQtyOnHand)
            END

            IF @CoitemQtyReady = 0 and @CoitemRefType <> 'I'
            begin
               select top 1
                @TtShipRowpointer = tt_ship.rowpointer
               ,@TtShipCoNum = tt_ship.co_num
               ,@TtShipCoLine = tt_ship.co_line
               ,@TtShipCoRelease = tt_ship.co_release
               ,@TtShipSequence = tt_ship.sequence
               ,@TtShipLoc = tt_ship.loc
               ,@TtShipLot = tt_ship.lot
               ,@TtShipUM = tt_ship.u_m
               ,@TtShipTcQtcToShip = tt_ship.tc_qtc_to_ship
               ,@TtShipTcQtcToShipConv = tt_ship.tc_qtc_to_ship_conv
               ,@TtShipShipStat = tt_ship.ship_stat
               from @tt_ship as tt_ship
               WHERE tt_ship.co_num = @CoitemCoNum
               AND tt_ship.co_line = @CoitemCoLine
               AND tt_ship.co_release = @CoitemCoRelease
               AND tt_ship.loc = @LotLocLoc
               AND tt_ship.lot IS NULL
               order by tt_ship.sequence asc
               if @@rowcount <> 1
                  set @TtShipRowpointer = null
            end
            ELSE
            begin
               select top 1
                @TtShipRowpointer = tt_ship.rowpointer
               ,@TtShipCoNum = tt_ship.co_num
               ,@TtShipCoLine = tt_ship.co_line
               ,@TtShipCoRelease = tt_ship.co_release
               ,@TtShipSequence = tt_ship.sequence
               ,@TtShipLoc = tt_ship.loc
               ,@TtShipLot = tt_ship.lot
               ,@TtShipUM = tt_ship.u_m
               ,@TtShipTcQtcToShip = tt_ship.tc_qtc_to_ship
               ,@TtShipTcQtcToShipConv = tt_ship.tc_qtc_to_ship_conv
               ,@TtShipShipStat = tt_ship.ship_stat
               from @tt_ship as tt_ship
               WHERE tt_ship.co_num = @CoitemCoNum
               AND tt_ship.co_line = @CoitemCoLine
               AND tt_ship.co_release = @CoitemCoRelease
               AND tt_ship.loc = @LotLocLoc
               AND tt_ship.lot = @LotLocLot
               order by tt_ship.sequence asc
               if @@rowcount <> 1
                  set @TtShipRowpointer = null
            end
            IF @TtShipRowpointer is null
            BEGIN
               set @TtShipRowpointer = newid()
               SET @TtShipCoNum = @CoitemCoNum
               SET @TtShipCoLine = @CoitemCoLine
               SET @TtShipCoRelease = @CoitemCoRelease
               SET @TtShipSequence = @NextSequence
               SET @NextSequence = @NextSequence + 1

               SET @TtShipLoc = @LotLocLoc
               SET @TtShipLot = CASE WHEN @WItemlocQtyOnHand > 0 THEN @LotLocLot ELSE NULL END
               SET @TtShipTcQtcToShip = dbo.MaxQty(0.0, dbo.MinQty(@WItemlocQtyOnHand, @QtyRemaining))
               SET @TtShipUM = @CoitemUM

               IF @CoitemRefType <> 'I'
                  SET @TtShipQtyToShip = dbo.MinQty(@TtShipTcQtcToShip, @CoitemQtyReady)
               ELSE
                  SET @TtShipQtyToShip = @TtShipTcQtcToShip

               SET @TtShipShipStat =
                  CASE WHEN @CoitemQtyShipped = 0.0 THEN 'O'  /* Ordered */
                  WHEN @CoitemQtyShipped >= @CoitemQtyOrdered THEN 'F'  /* Filled */
                  ELSE 'P' /* Partially Shipped */
                  END

               insert into @tt_ship (rowpointer, co_num, co_line, co_release, sequence, loc, lot, tc_qtc_to_ship, u_m, ship_stat)
               values(@TtShipRowpointer, @TtShipCoNum, @TtShipCoLine, @TtShipCoRelease, @TtShipSequence, @TtShipLoc, @TtShipLot, @TtShipQtyToShip, @TtShipUM, @TtShipShipStat)
            END
            ELSE
            BEGIN
               SET @TtShipTcQtcToShip = dbo.MaxQty(0.0, @TtShipTcQtcToShip
                  + dbo.MinQty(dbo.MaxQty(0.0, @WItemlocQtyOnHand), @QtyRemaining))
               SET @TtShipQtyToShip = @TtShipTcQtcToShip
            END

            SET @TtShipTcQtcToShipConv = dbo.uomconvqty(@TtShipQtyToShip,
               @UomConvFactor,
               'From Base')

            update @tt_ship
            set
             tc_qtc_to_ship = @TtShipQtyToShip
            ,tc_qtc_to_ship_conv = @TtShipTcQtcToShipConv
            where rowpointer = @TtShipRowpointer

            /* Remove rows that have zero qty to ship except at least one row for a CO, CO Line, CO Release combination */
            /* If there is at least one row that has a non-zero qty to ship for a CO, CO Line, CO Release combination
             * delete all other rows that have zero qty to ship */
            IF EXISTS( SELECT TOP 1 1
                       FROM @tt_ship
                       WHERE co_num = @TtShipCoNum
                       AND co_line = @TtShipCoLine
                       AND co_release = @TtShipCoRelease
                       AND tc_qtc_to_ship <> 0 )
            BEGIN
               DELETE FROM @tt_ship
               WHERE co_num = @TtShipCoNum
               AND co_line = @TtShipCoLine
               AND co_release = @TtShipCoRelease
               AND tc_qtc_to_ship = 0
            END
            ELSE
            /* If all rows have zero qty to ship for a CO, CO Line, CO Release combination
             * delete all rows except first one */
            BEGIN
               SET @TtShipFirstSequence = NULL
               SELECT TOP 1 @TtShipFirstSequence = sequence
               FROM @tt_ship
               WHERE co_num = @TtShipCoNum
               AND co_line = @TtShipCoLine
               AND co_release = @TtShipCoRelease
               AND tc_qtc_to_ship = 0
               ORDER BY co_num, co_line, co_release, sequence ASC

               IF @TtShipFirstSequence IS NOT NULL
                  DELETE FROM @tt_ship
                  WHERE co_num = @TtShipCoNum
                  AND co_line = @TtShipCoLine
                  AND co_release = @TtShipCoRelease
                  AND tc_qtc_to_ship = 0
                  AND sequence > @TtShipFirstSequence
            END

            SET @QtyRemaining = @QtyRemaining - @TtShipTcQtcToShip
            SET @WItemlocQtyOnHand = @WItemlocQtyOnHand - @TtShipTcQtcToShip

            update @w_itemloc
            set qty_on_hand = @WItemlocQtyOnHand
            where rowpointer = @WItemlocRowpointer

            if @CoitemRefType <> 'I' and @CoitemQtyReady = 0
               BREAK
         END /* repeat loop for lot tracked & issued by loc */
         /* not lot tracked */
         ELSE
         BEGIN
            select top 1
             @WItemlocRowpointer = w_itemloc.rowpointer
            ,@WItemlocItem = w_itemloc.item
            ,@WItemlocLoc = w_itemloc.loc
            ,@WItemlocLot = w_itemloc.lot
            ,@WItemlocQtyOnHand = w_itemloc.qty_on_hand
            from @w_itemloc as w_itemloc
            WHERE w_itemloc.item = @ItemlocItem
            AND w_itemloc.loc = @ItemlocLoc
            order by w_itemloc.item asc, w_itemloc.loc asc, w_itemloc.lot asc
            if @@rowcount <> 1
               set @WItemlocRowpointer = null

            IF @WItemlocRowpointer is null
            BEGIN
               set @WItemlocRowpointer = newid()
               SET @WItemlocItem = @ItemlocItem
               SET @WItemlocLoc = @ItemlocLoc
               SET @WItemlocLot = NULL
               SET @WItemlocQtyOnHand = @ItemlocQtyOnHand - @ItemlocQtyRsvd
               insert into @w_itemloc (rowpointer, item, loc, lot, qty_on_hand)
               values(@WItemlocRowpointer, @WItemlocItem, @WItemlocLoc, @WItemlocLot, @WItemlocQtyOnHand)
            END

            select top 1
             @TtShipRowpointer = tt_ship.rowpointer
            ,@TtShipCoNum = tt_ship.co_num
            ,@TtShipCoLine = tt_ship.co_line
            ,@TtShipCoRelease = tt_ship.co_release
            ,@TtShipSequence = tt_ship.sequence
            ,@TtShipLoc = tt_ship.loc
            ,@TtShipLot = tt_ship.lot
            ,@TtShipUM = tt_ship.u_m
            ,@TtShipTcQtcToShip = tt_ship.tc_qtc_to_ship
            ,@TtShipTcQtcToShipConv = tt_ship.tc_qtc_to_ship_conv
            ,@TtShipShipStat = tt_ship.ship_stat
            from @tt_ship as tt_ship
            WHERE tt_ship.co_num = @CoitemCoNum
            AND tt_ship.co_line = @CoitemCoLine
            AND tt_ship.co_release = @CoitemCoRelease
            AND tt_ship.loc = @ItemlocLoc
            order by tt_ship.sequence asc
            if @@rowcount <> 1
               set @TtShipRowpointer = null

            IF @TtShipRowpointer is null
            BEGIN
               set @TtShipRowpointer = newid()
               SET @TtShipCoNum = @CoitemCoNum
               SET @TtShipCoLine = @CoitemCoLine
               SET @TtShipCoRelease = @CoitemCoRelease
               SET @TtShipSequence = @NextSequence
               SET @NextSequence = @NextSequence + 1

               SET @TtShipLoc = @ItemlocLoc
               SET @TtShipLot = NULL
               SET @TtShipTcQtcToShip = dbo.MaxQty(0.0, dbo.MinQty(@WItemlocQtyOnHand, @QtyRemaining))
               SET @TtShipUM = @CoitemUM

               IF @CoitemRefType <> 'I'
                  SET @TtShipQtyToShip = dbo.MinQty(@TtShipTcQtcToShip, @CoitemQtyReady)
               ELSE
                  SET @TtShipQtyToShip = @TtShipTcQtcToShip

               SET @TtShipShipStat =
                  CASE WHEN @CoitemQtyShipped = 0.0 THEN 'O'  /* Ordered */
                  WHEN @CoitemQtyShipped >= @CoitemQtyOrdered THEN 'F'  /* Filled */
                  ELSE 'P' /* Partially Shipped */
                  END

               insert into @tt_ship (rowpointer, co_num, co_line, co_release, sequence, loc, lot, tc_qtc_to_ship, u_m, ship_stat)
               values(@TtShipRowpointer, @TtShipCoNum, @TtShipCoLine, @TtShipCoRelease, @TtShipSequence, @TtShipLoc, @TtShipLot, @TtShipQtyToShip, @TtShipUM, @TtShipShipStat)
            END
            ELSE
            BEGIN
               SET @TtShipTcQtcToShip = dbo.MaxQty(0.0, @TtShipTcQtcToShip
                  + dbo.MinQty(dbo.MaxQty(0.0, @WItemlocQtyOnHand), @QtyRemaining))
               SET @TtShipQtyToShip = @TtShipTcQtcToShip
            END

            SET @TtShipTcQtcToShipConv = dbo.uomconvqty(@TtShipQtyToShip,
               @UomConvFactor,
               'From Base')

            update @tt_ship
            set
             tc_qtc_to_ship = @TtShipQtyToShip
            ,tc_qtc_to_ship_conv = @TtShipTcQtcToShipConv
            where rowpointer = @TtShipRowpointer

            /* Remove rows that have zero qty to ship except at least one row for a CO, CO Line, CO Release combination */
            /* If there is at least one row that has a non-zero qty to ship for a CO, CO Line, CO Release combination
             * delete all other rows that have zero qty to ship */
            IF EXISTS( SELECT TOP 1 1
                       FROM @tt_ship
                       WHERE co_num = @TtShipCoNum
                       AND co_line = @TtShipCoLine
                       AND co_release = @TtShipCoRelease
                       AND tc_qtc_to_ship <> 0 )
            BEGIN
               DELETE FROM @tt_ship
               WHERE co_num = @TtShipCoNum
               AND co_line = @TtShipCoLine
               AND co_release = @TtShipCoRelease
               AND tc_qtc_to_ship = 0
            END
            ELSE
            /* If all rows have zero qty to ship for a CO, CO Line, CO Release combination
             * delete all rows except first one */
            BEGIN
               SET @TtShipFirstSequence = NULL
               SELECT TOP 1 @TtShipFirstSequence = sequence
               FROM @tt_ship
               WHERE co_num = @TtShipCoNum
               AND co_line = @TtShipCoLine
               AND co_release = @TtShipCoRelease
               AND tc_qtc_to_ship = 0
               ORDER BY co_num, co_line, co_release, sequence ASC

               IF @TtShipFirstSequence IS NOT NULL
                  DELETE FROM @tt_ship
                  WHERE co_num = @TtShipCoNum
                  AND co_line = @TtShipCoLine
                  AND co_release = @TtShipCoRelease
                  AND tc_qtc_to_ship = 0
                  AND sequence > @TtShipFirstSequence
            END

            SET @QtyRemaining = @QtyRemaining - @TtShipTcQtcToShip
            SET @WItemlocQtyOnHand = @WItemlocQtyOnHand - @TtShipTcQtcToShip

            update @w_itemloc
            set qty_on_hand = @WItemlocQtyOnHand
            where rowpointer = @WItemlocRowpointer
         END

         SET @FirstItemloc = 0
      END /* repeat while @QtyRemaining > 0.0: */
end
close coitem_crs
deallocate coitem_crs

SELECT
   tt_ship.co_num AS CoNum,
   tt_ship.co_line AS CoLine,
   tt_ship.co_release AS CoRelease,
   coitem.NoteExistsFlag,
   coitem.RowPointer,
   tt_ship.u_m AS UM,
   tt_ship.ship_stat AS DerShipStat,
   co.cust_num AS CoCustNum,
   custaddr.name AS AdrName,
   co.stat AS CoStat,
   coitem.due_date AS DueDate,
   coitem.Stat,
   coitem.qty_ordered_conv AS QtyOrderedConv,
   dbo.UomConvQty(coitem.qty_shipped, dbo.Getumcf(coitem.u_m, coitem.item, co.cust_num, N'C') ,N'From Base') AS DerQtyShippedConv,
   dbo.UomConvQty(coitem.qty_returned, dbo.Getumcf(coitem.u_m, coitem.item, co.cust_num, N'C') ,N'From Base') AS DerQtyReturnedConv,
   dbo.UomConvQty(coitem.qty_invoiced, dbo.Getumcf(coitem.u_m, coitem.item, co.cust_num, N'C') ,N'From Base') AS DerQtyInvoicedConv,
   co.einvoice AS CoEinvoice,
   co.ship_early AS CoShipEarly,
   co.ship_partial AS CoShipPartial,
   coitem.item AS Item,
   coitem.description AS ItDescription,
   coitem.ref_type AS RefType,
   coitem.ref_num AS RefNum,
   coitem.ref_line_suf AS RefLineSuf,
   coitem.ref_release AS RefRelease,
   coitem.ship_date AS ShipDate,
   dbo.UomConvQty(IsNull(itemwhse.qty_on_hand, 0)
      + coitem.qty_ordered
      - coitem.qty_shipped
      - IsNull(itemwhse.alloc_trn, 0)
      - IsNull(itemwhse.qty_alloc_co, 0)
      - (CASE when coitem.whse = @DefWhse THEN IsNull(item.qty_allocjob, 0) ELSE 0 END)
   ,dbo.Getumcf(coitem.u_m, coitem.item, co.cust_num, N'C'),N'From Base') AS DerQtyAvailableConv,
   dbo.UomConvQty(itemwhse.qty_on_hand, dbo.Getumcf(coitem.u_m, coitem.item, co.cust_num, N'C') ,N'From Base') AS DerItwhsQtyOnHandConv,
   item.serial_tracked AS ItSerialTracked,
   coitem.Whse,
   item.lot_tracked AS ItLotTracked,
   co.fixed_rate AS CoFixedRate,
   Case when coitem.cust_num is not null then 1 else 0 end AS DerDropShipFlag,
   coitem.u_m AS DerUM,
   IsNull(itemwhse.qty_on_hand, 0)
      + coitem.qty_ordered
      - coitem.qty_shipped
      - IsNull(itemwhse.alloc_trn, 0)
      - IsNull(itemwhse.qty_alloc_co, 0)
      - (CASE when coitem.whse = @DefWhse THEN IsNull(item.qty_allocjob, 0) ELSE 0 END)
    AS DerQtyAvailable,
   itemwhse.qty_on_hand AS ItwhsQtyOnHand,
   coitem.qty_ordered AS QtyOrdered,
   coitem.qty_returned AS QtyReturned,
   coitem.qty_shipped AS QtyShipped,
   coitem.qty_invoiced AS QtyInvoiced,
   tt_ship.loc AS Loc,
   tt_ship.lot AS Lot,
   tt_ship.tc_qtc_to_ship AS DerQtyToShip,
   tt_ship.tc_qtc_to_ship_conv AS DerQtyToShipConv,
   1 as UbRtnToStk,
   0 as UbCrReturn,
   customer.print_pack_inv AS PrintPackInv,
   item.reservable AS ItReservable,
   item.tax_free_matl AS ItTaxFreeMatl,
   co.export_type AS CoExportType,
   item.track_pieces AS ItemTrackPieces,
   item.dimension_group AS ItemDimensionGroup,
   NULL AS StartingSerial,
   NULL AS EndingSerial,
   NULL AS ContainerNum,
   coitem.manufacturer_id AS ManufacturerId,
   coitem.manufacturer_item AS ManufacturerItem,
   man.name AS ManufacturerName,
   mai.description AS ManufacturerItemDesc,
   coitem.RecordDate AS RecordDate,
   @CoType AS UbCoType,
   dbo.GetNegShipmentQty(tt_ship.co_num,tt_ship.co_line,tt_ship.co_release) AS DerNegShipmentQty,
   country.ec_code AS CouEcCode,
   taxcode.tax_code_type AS CusTaxCode1Type
FROM @tt_ship AS tt_ship
INNER JOIN co ON co.co_num = tt_ship.co_num
INNER JOIN coitem
   ON coitem.co_num = tt_ship.co_num
   AND coitem.co_line = tt_ship.co_line
   AND coitem.co_release = tt_ship.co_release
LEFT OUTER JOIN item WITH (READUNCOMMITTED) ON item.item = coitem.item
LEFT OUTER JOIN itemwhse with (readuncommitted)
   ON itemwhse.item = coitem.item
   AND itemwhse.Whse = coitem.whse
inner JOIN custaddr with (readuncommitted)
   ON custaddr.cust_num = co.cust_num
   AND custaddr.cust_seq = co.cust_seq
inner JOIN customer with (readuncommitted)
   ON customer.cust_num = co.cust_num
   AND customer.cust_seq = 0
LEFT OUTER JOIN manufacturer AS man with (readuncommitted) ON man.manufacturer_id = coitem.manufacturer_id
LEFT OUTER JOIN manufacturer_item AS mai with (readuncommitted)
   ON mai.manufacturer_id = coitem.manufacturer_id
   AND mai.manufacturer_item = coitem.manufacturer_item
LEFT OUTER JOIN customer ShipTo with (readuncommitted) on ShipTo.cust_num = co.cust_num and ShipTo.cust_seq = co.cust_seq   
LEFT OUTER JOIN country with (readuncommitted) on country.country = custaddr.country   
LEFT OUTER JOIN taxcode with (readuncommitted) on taxcode.tax_system = 1 and taxcode.tax_code = ShipTo.tax_code1
ORDER BY CoNum, CoLine, CoRelease, Sequence

RETURN @Severity
GO


