USE [KPI_App]
GO

/****** Object:  StoredProcedure [dbo].[CoPackingSlipLoadSp]    Script Date: 09/06/2017 11:22:06 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

/* $Header: /ApplicationDB/Stored Procedures/CoPackingSlipLoadSp.sp 32    6/22/15 12:42p Ltaylor2 $ */
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
*   (c) COPYRIGHT 2010 INFOR.  ALL RIGHTS RESERVED.           *
*   THE WORD AND DESIGN MARKS SET FORTH HEREIN ARE            *
*   TRADEMARKS AND/OR REGISTERED TRADEMARKS OF INFOR          *
*   AND/OR ITS AFFILIATES AND SUBSIDIARIES. ALL RIGHTS        *
*   RESERVED.  ALL OTHER TRADEMARKS LISTED HEREIN ARE         *
*   THE PROPERTY OF THEIR RESPECTIVE OWNERS.                  *
*                                                             *
*************************************************************** 
*/
/* $Archive: /ApplicationDB/Stored Procedures/CoPackingSlipLoadSp.sp $
 *
 * SL9.00 32 194911 Ltaylor2 Mon Jun 22 12:42:03 2015
 * Not able to print order packing slip for delivery order line sequence.
 * Issue 194911 - Don't include do_qty_shipped in calculations, we don't care what was shipped with a DO we just care about what was packed with a DO.
 *
 * SL9.00 31 194092 Shu Wed Apr 29 23:10:36 2015
 * Coding for RS6710 - 1-Pick/Pack/Ship-Unship Shipments
 * Issue 194092(RS6710): Change QTS calculation
 *
 * SL8.04 30 164939 Bbai Tue Jul 16 05:04:45 2013
 * On the PackingSlip form, the Qty to Pack for Ship/Pre Ship is not right.
 * 164939:
 * Correct do_num condition for @ship_qty_shipped.
 *
 * SL8.04 29 RS6252 Ezhang1 Mon Jun 03 04:53:29 2013
 * RS6252
 *
 * SL8.04 28 RS6252 Bqin Sun Jun 02 21:20:34 2013
 * RS6252: Update the SP logic according to the design.
 *
 * SL8.04 26 152613 pgross Mon Dec 31 15:54:33 2012
 * Error message printing packing slip for edi customer order
 * do not allow packing more than available when printing the packing slip on invoices
 *
 * SL8.03 25 RS3639 Jpan2 Tue Feb 22 04:19:09 2011
 * RS3639 get UM and Description from coitem if item is a non-inventory item.
 *
 * SL8.02 24 rs4588 Dahn Thu Mar 04 10:27:30 2010
 * RS4588 Copyright header changes
 *
 * SL8.02 23 rs4588 Dahn Thu Mar 04 09:37:18 2010
 * RS4588 Copyright header changes
 *
 * SL8.02 22 121361 Mewing Mon Oct 12 14:51:23 2009
 * SL8.02 00 121361  All references to BatchId2Type need to be changed back to BatchIdType.  This checkin will affect stored procedures, triggers, functions.
 * Schema, property classes and component classes will be done seperately.
 *
 * SL8.01 21 118985 Cajones Mon May 18 14:47:26 2009
 * Unable to generate a Batch ID more than 99 at Shipping Processing Orders
 * Issue:118985,APAR:115322 - Changed references of type BatchIdType (defined as tinyint) to new UDDT BatchId2Type (defined as int).  This change is to allow the user to enter a 6 digit batch id number.
 *
 * SL8.01 20 rs3953 Vlitmano Wed Aug 27 11:02:52 2008
 * RS3953 - Changed a Copyright header?
 *
 * SL8.00 18 105354 Debmcw Tue Sep 18 17:02:00 2007
 * Quantity to Pack is negative on Packing Slip Selection 
 * 105354 - Subtract out any qty_packed associated with a DO when calculating qty_to_pack.
 *
 * SL8.00 17 101988 Dahn Tue Sep 04 13:29:32 2007
 * SQL Objects Wording - Some SPs and Numerous Scalar- Valued Functions
 * Changed header's comment (file dbo.AcctChgSp) to "Copyright ? 2007 Infor Global Solutions Technology GmbH, and/or its affiliate and subsidiaries.  All rights reserved.  The word and design marks set forth herein are trademarks and/or registered trademarks of Infor Global Solutions Technology GmbH and/or its affiliate and subsidiaries.  All rights reserved.  All other trademarks listed herein are the property of their respective owners."
 *
 * SL8.00 16 100972 Hcl-tayamoh Thu Apr 12 04:31:12 2007
 * Quantity shipped is truncated to 2 decimal place instead of displaying the actual unit shipped on the CO line
 * Issue 100972
 * removed rounding for QtyToPackConv
 *
 * SL8.00 15 rs2968 nkaleel Fri Feb 23 01:11:46 2007
 * changing copyright information
 *
 * SL8.00 14 RS2968 prahaladarao.hs Thu Jul 13 02:46:22 2006
 * RS 2968, Name change CopyRight Update.
 *
 * SL8.00 13 RS2968 prahaladarao.hs Tue Jul 11 05:24:58 2006
 * RS 2968
 * Name change CopyRight Update.
 *
 * SL8.00 12 94580 Hcl-tayamoh Thu Jun 01 06:44:21 2006
 * Wrong qty appearing in Packing Slip Selection form when u/m conversion exists
 * issue 94580
 * while calling dbo.GetumcfSp
 * @Area    =NULL is replaced by @Area    = 'C'
 *
 * SL8.00 11 94382 Hcl-ajain Fri May 26 08:52:23 2006
 * Cannot print packing slip quantity to pack wrong value?
 * Issue #94382
 * 1. Now taking only those shipping which are not shipped against any DO.
 *    Deducting DO shipments from Total qty shipped and DO Packing slips generated from  total qty    packed for DO.
 *
 * SL7.05 10 91818 NThurn Fri Jan 06 14:30:28 2006
 * Inserted standard External Touch Point call.  (RS3177)
 *
 * $NoKeywords: $
 */
CREATE PROCEDURE [dbo].[CoPackingSlipLoadSp] (    
  @TPckCall      SYSNAME -- CO-SHIP or PRE-SHIP (07/03/02 added CO-SHIP-FROMSHIPITEM case)    
, @CoNum         CoNumType    
, @CustNum       CustNumType    
, @CoitemCustNum CustNumType    
, @CoitemCustSeq CustSeqType    
, @Whse          WhseType    
, @FromCoLine    CoLineType    
, @ToCoLine      CoLineType    
, @FromCoRelease CoReleaseType    
, @ToCoRelease   CoReleaseType    
, @FromDate      DateType    
, @ToDate        DateType    
, @Stat          NVARCHAR(8)    
, @BatchId       BatchIdType = NULL    
)    
AS    
    
   -- Check for existence of Generic External Touch Point routine (this section was generated by SpETPCodeSp and inserted by CallETPs.exe):    
   IF OBJECT_ID(N'dbo.EXTGEN_CoPackingSlipLoadSp') IS NOT NULL    
   BEGIN    
      DECLARE @EXTGEN_SpName sysname    
      SET @EXTGEN_SpName = N'dbo.EXTGEN_CoPackingSlipLoadSp'    
      -- Invoke the ETP routine, passing in (and out) this routine's parameters:    
      EXEC @EXTGEN_SpName    
         @TPckCall    
         , @CoNum    
         , @CustNum    
         , @CoitemCustNum    
         , @CoitemCustSeq    
         , @Whse    
         , @FromCoLine    
         , @ToCoLine    
         , @FromCoRelease    
         , @ToCoRelease    
         , @FromDate    
         , @ToDate    
         , @Stat    
         , @BatchId    
     
      -- ETP routine must take over all desired functionality of this standard routine:    
      RETURN 0    
   END    
   -- End of Generic External Touch Point code.    
     
DECLARE    
  @Severity      INT    
, @Infobar       InfobarType    
, @ConvCoLine    CoLineType    
, @ConvCoRelease CoReleaseType    
, @ConvUM        UMType    
, @ConvItem      ItemType    
, @ConvFactor    UMConvFactorType    
, @ParmsSite     SiteType    
, @DefWhse       WhseType    
, @FromShipItem  FlagNyType    
, @FromShipCo    FlagNyType    
, @InvparmsPlacesQtyCum DecimalPlacesType    
, @do_qty_shipped QtyUnitType    
, @ship_qty_shipped     QtyUnitType    
, @other_qty_shipped    QtyUnitType    
, @tot_qty_packed QtyUnitNoNegType    
, @tot_qty_Shipped QtyUnitNoNegType    
, @CO_qty_packed QtyUnitNoNegType    
    
SET @Severity      = 0    
SET @FromShipItem  = 0    
SET @FromShipCo    = 0    
SET @FromCoLine    = ISNULL(@FromCoLine, dbo.LowAnyInt('CoLineType'))    
SET @ToCoLine      = ISNULL(@ToCoLine, dbo.HighAnyInt('CoLineType'))    
SET @FromCoRelease = ISNULL(@FromCoRelease, dbo.LowAnyInt('CoReleaseType'))    
SET @ToCoRelease   = ISNULL(@ToCoRelease, dbo.HighAnyInt('CoReleaseType'))    
SET @FromDate      = ISNULL(@FromDate,dbo.LowDate())    
SET @ToDate        = ISNULL(@ToDate,dbo.HighDate())    
    
IF @TPckCall = 'CO-SHIP-FROMSHIPITEM'    
BEGIN    
   SET @TPckCall = 'CO-SHIP'    
   SET @Stat = 'POFC'    
   SET @FromShipItem = 1    
END    
ELSE IF @TPckCall = 'CO-SHIP-FROMSHIPCO'    
BEGIN    
   SET @Stat = 'POFC'    
   SET @FromShipCo = 1    
END    
    
SELECT @ParmsSite = parms.site    
FROM parms with (readuncommitted)    
WHERE parms.parm_key = 0    
    
SELECT @DefWhse = invparms.def_whse    
, @InvparmsPlacesQtyCum = invparms.places_qty_cum    
FROM invparms with (readuncommitted)    
WHERE invparms.parm_key = 0    
    
SET @Whse = ISNULL(@Whse,@DefWhse)    
    
SELECT    
  coitem.co_line AS co_line    
, coitem.co_release AS co_release    
, coitem.qty_packed AS qty_packed    
, coitem.qty_packed AS qty_to_pack    
, coitem.qty_packed AS qty_to_pack_conv    
, coitem.qty_packed AS max_qty_to_pack_conv    
, coitem.qty_ordered AS qty_ordered    
, coitem.qty_ordered_conv as qty_ordered_conv    
, coitem.u_m AS u_m    
, coitem.item AS item    
, item.description AS item_desc    
, item.u_m AS item_um    
, coitem.qty_invoiced As qty_invoiced    
, coitem.qty_shipped As qty_shipped    
INTO #w_coitem    
FROM coitem    
INNER JOIN item ON    
  1=2    
WHERE 1=2    
    
INSERT INTO #w_coitem (    
  co_line, co_release, qty_packed, qty_to_pack, qty_to_pack_conv, max_qty_to_pack_conv, qty_ordered, qty_ordered_conv, item, item_desc, item_um,    
  u_m, qty_invoiced, qty_shipped    
  ) SELECT    
  coitem.co_line    
, coitem.co_release    
, coitem.qty_packed   -- qty_packed, inital value, needs um convert.    
, (CASE WHEN @TPckCall = 'CO-SHIP' THEN    
   coitem.qty_shipped - coitem.qty_packed    
   ELSE  -- PRE-SHIP    
   coitem.qty_ordered - coitem.qty_packed    
   END) --               -- qty_to_pack default value.    
, (CASE WHEN @TPckCall = 'CO-SHIP' THEN    
   coitem.qty_shipped - coitem.qty_packed    
   ELSE  -- PRE-SHIP    
   coitem.qty_ordered - coitem.qty_packed    
   END) -- qty_to_pack_conv defaults to qty_to_pack.  Calculated later, if needed.    
, (CASE WHEN @TPckCall = 'CO-SHIP' THEN    
   coitem.qty_shipped - coitem.qty_packed    
   ELSE  -- PRE-SHIP    
   coitem.qty_ordered - coitem.qty_packed    
   END) -- max_qty_to_pack_conv defaults to qty_to_pack.  Calculated later, if needed.    
, coitem.qty_ordered -- qty_ordered    
, coitem.qty_ordered_conv -- qty_ordered_conv    
, coitem.item        -- item    
, ISNULL(item.description, coitem.description)   -- item_desc    
, ISNULL(item.u_m, coitem.u_m)           -- item_um    
, coitem.u_m         -- u_m    
, coitem.qty_invoiced -- qty_invoiced    
, coitem.qty_shipped -- qty_shipped    
FROM coitem    
LEFT OUTER JOIN item ON    
  coitem.item = item.item    
LEFT OUTER JOIN shipitem ON    
    coitem.co_num  = shipitem.co_num    
AND coitem.co_line = shipitem.co_line    
AND coitem.co_release = shipitem.co_release    
AND shipitem.batch_id = ISNULL(@BatchId,shipitem.batch_id)    
LEFT OUTER JOIN shipco ON    
    coitem.co_num = shipco.co_num    
AND shipco.batch_id = ISNULL(@BatchId,shipco.batch_id)    
WHERE coitem.co_num = @CoNum    
AND   ISNULL(coitem.cust_num, '') = ISNULL(@CoitemCustNum,'')    
AND   ISNULL(coitem.cust_seq, 0) = ISNULL(@CoitemCustSeq, 0)    
AND   coitem.co_line BETWEEN @FromCoLine AND @ToCoLine    
AND   coitem.co_release BETWEEN @FromCoRelease AND @ToCoRelease    
AND   coitem.due_date BETWEEN @FromDate AND @ToDate    
AND   coitem.qty_packed < (CASE WHEN @TPckCall = 'CO-SHIP'    
  THEN coitem.qty_shipped    
  ELSE coitem.qty_ordered END)    
AND   coitem.whse = @Whse    
AND   coitem.ship_site = @ParmsSite    
AND   CHARINDEX (coitem.stat, @Stat) > 0    
AND   1 = (CASE WHEN @FromShipItem = 1    
  THEN shipitem.active    
  WHEN @FromShipCo = 1    
  THEN shipco.active    
  ELSE 1 END)    
    
DECLARE    
  CoPackingSlipLoadSpCrs2 CURSOR LOCAL STATIC FOR    
SELECT DISTINCT    
  #w_coitem.co_line    
, #w_coitem.co_release    
, #w_coitem.u_m    
, #w_coitem.item    
FROM #w_coitem    
where u_m = item_um    
    
OPEN CoPackingSlipLoadSpCrs2    
WHILE @Severity = 0    
BEGIN    
   FETCH CoPackingSlipLoadSpCrs2 INTO    
     @ConvCoLine    
   , @ConvCoRelease    
   , @ConvUM    
   , @ConvItem    
    
   IF @@FETCH_STATUS = -1    
      BREAK    
    
   SELECT @tot_qty_packed = coitem.qty_packed,@tot_qty_Shipped=qty_shipped FROM coitem  WHERE coitem.co_num = @CoNum    
   AND coitem.co_line = @ConvCoLine    
   AND coitem.co_release = @ConvCoRelease    
       
   SELECT @CO_qty_packed = ISNULL(SUM(pckitem.qty_packed),0)from pckitem    
   WHERE pckitem.co_num = @CoNum    
   AND pckitem.co_line = @ConvCoLine    
   AND pckitem.co_release = @ConvCoRelease    
      
   /* Subtract out any qty_packed associated with a DO */    
   SELECT @CO_qty_packed = @CO_qty_packed - ISNULL(SUM(pckitem.qty_packed),0)    
   from pckitem    
   LEFT OUTER JOIN co_ship ON    
     co_ship.co_num = pckitem.co_num AND    
     co_ship.co_line = pckitem.co_line AND    
     co_ship.co_release = pckitem.co_release AND    
     co_ship.pack_num = pckitem.pack_num      
   WHERE pckitem.co_num = @CoNum    
   AND pckitem.co_line = @ConvCoLine    
   AND pckitem.co_release = @ConvCoRelease    
   AND co_ship.do_num IS NOT NULL    
      
   SELECT @ship_qty_shipped = ISNULL(SUM(qty_shipped),0)    
   FROM co_ship     
   WHERE co_num = @CoNum    
   AND co_line= @ConvCoLine    
   AND co_release = @ConvCoRelease     
   AND do_num is null    
   AND shipment_id is not null    
       
   SET @other_qty_shipped = @ship_qty_shipped   
       
   IF @other_qty_shipped > 0    
   BEGIN    
       UPDATE #w_coitem     
       SET qty_to_pack_conv= (@tot_qty_shipped - @other_qty_shipped) - (@CO_qty_packed)          
       ,qty_to_pack = (@tot_qty_shipped - @other_qty_shipped) - (@CO_qty_packed)    
       ,max_qty_to_pack_conv=(@tot_qty_shipped - @other_qty_shipped) - (@CO_qty_packed)     
       WHERE #w_coitem.co_line = @ConvCoLine    
       AND   #w_coitem.co_release = @ConvCoRelease    
   END    
END    
CLOSE CoPackingSlipLoadSpCrs2    
DEALLOCATE CoPackingSlipLoadSpCrs2    
    
DECLARE    
  CoPackingSlipLoadSpCrs CURSOR LOCAL STATIC FOR    
SELECT DISTINCT    
  #w_coitem.co_line    
, #w_coitem.co_release    
, #w_coitem.u_m    
, #w_coitem.item    
FROM #w_coitem    
where u_m != item_um    
    
OPEN CoPackingSlipLoadSpCrs    
WHILE @Severity = 0    
BEGIN    
   FETCH CoPackingSlipLoadSpCrs INTO    
     @ConvCoLine    
   , @ConvCoRelease    
   , @ConvUM    
   , @ConvItem    
    
   IF @@FETCH_STATUS = -1    
      BREAK    
    
   EXEC @Severity = dbo.GetumcfSp    
     @OtherUM = @ConvUM    
   , @Item    = @ConvItem    
   , @VendNum = @CustNum    
   , @Area    = 'C'    
   , @ConvFactor = @ConvFactor OUTPUT    
   , @Infobar    = @Infobar    OUTPUT    
   , @Site = @ParmsSite    
    
   SELECT @tot_qty_packed = coitem.qty_packed,@tot_qty_Shipped=qty_shipped FROM coitem  WHERE coitem.co_num = @CoNum    
   AND coitem.co_line = @ConvCoLine    
   AND coitem.co_release = @ConvCoRelease    
       
   SELECT @CO_qty_packed = ISNULL(SUM(pckitem.qty_packed),0)from pckitem    
   WHERE pckitem.co_num = @CoNum    
   AND pckitem.co_line = @ConvCoLine    
   AND pckitem.co_release = @ConvCoRelease    
       
   /* Subtract out any qty_packed associated with a DO */    
   SELECT @CO_qty_packed = @CO_qty_packed - ISNULL(SUM(pckitem.qty_packed),0)    
   from pckitem    
   LEFT OUTER JOIN co_ship ON    
     co_ship.co_num = pckitem.co_num AND    
     co_ship.co_line = pckitem.co_line AND    
     co_ship.co_release = pckitem.co_release AND    
     co_ship.pack_num = pckitem.pack_num      
   WHERE pckitem.co_num = @CoNum    
   AND pckitem.co_line = @ConvCoLine    
   AND pckitem.co_release = @ConvCoRelease    
   AND co_ship.do_num IS NOT NULL    
    
     
   UPDATE #w_coitem    
   SET qty_packed = dbo.UomConvQty(qty_packed, @ConvFactor, 'From Base')    
   , qty_to_pack_conv  = dbo.UomConvQty(qty_to_pack, @ConvFactor, 'From Base')    
   , max_qty_to_pack_conv = dbo.UomConvQty(qty_to_pack, @ConvFactor, 'From Base')    
   WHERE #w_coitem.co_line = @ConvCoLine    
   AND   #w_coitem.co_release = @ConvCoRelease    
    
    
   SELECT @ship_qty_shipped = ISNULL(SUM(qty_shipped),0)    
   FROM co_ship     
   WHERE co_num = @CoNum    
   AND co_line= @ConvCoLine    
   AND co_release = @ConvCoRelease     
   AND do_num is null    
   AND shipment_id is not null    
       
   SET @other_qty_shipped = @ship_qty_shipped   
       
   IF @other_qty_shipped > 0    
   BEGIN    
       UPDATE #w_coitem     
       SET qty_to_pack_conv= (@tot_qty_shipped - @other_qty_shipped) - (@CO_qty_packed)        
           ,qty_to_pack = (@tot_qty_shipped - @other_qty_shipped) - (@CO_qty_packed)    
           ,max_qty_to_pack_conv=(@tot_qty_shipped - @other_qty_shipped) - (@CO_qty_packed)    
     WHERE #w_coitem.co_line = @ConvCoLine    
       AND   #w_coitem.co_release = @ConvCoRelease    
   END    
    
    
    
END    
CLOSE CoPackingSlipLoadSpCrs    
DEALLOCATE CoPackingSlipLoadSpCrs    
    
IF @TPckCall = 'PRE-SHIP'    
BEGIN    
    DECLARE     
    @pckitem_qty_packed   QtyUnitType    
   ,@qty_to_pick          QtyUnitType    
   ,@qty_picked           QtyUnitType    
   ,@qty_to_ship          QtyUnitType    
   ,@pick_pack_ship_qty   QtyUnitType    
       
   SELECT @pckitem_qty_packed = ISNULL(SUM(pckitem.qty_packed),0)    
   FROM  pckitem    
   WHERE pckitem.co_num = @CoNum    
     AND pckitem.co_line = @ConvCoLine    
     AND pckitem.co_release = @ConvCoRelease    
         
   SELECT @qty_to_pick = ISNULL(SUM(picklistref.qty_to_pick),0)    
   FROM pick_list_ref picklistref    
     JOIN pick_list picklist ON picklist.pick_list_id = picklistref.pick_list_id    
   WHERE picklistref.ref_line_suf = @ConvCoLine    
     AND picklistref.ref_release = @ConvCoRelease    
     AND picklistref.ref_num  =@CoNum    
     AND picklist.status = 'O'    
       
   SELECT @qty_picked  = ISNULL(SUM(picklistref.qty_picked),0)    
   FROM pick_list_ref picklistref    
        JOIN pick_list picklist ON picklist.pick_list_id = picklistref.pick_list_id    
   WHERE picklistref.ref_line_suf = @ConvCoLine    
        AND picklistref.ref_release = @ConvCoRelease    
        AND picklistref.ref_num  =@CoNum    
        AND picklist.status = 'P'    
             
   SELECT    
   @qty_to_ship = SUM(ISNULL(shipseq.qty_picked,0) - ISNULL(shipseq.qty_shipped, 0)) 
      FROM shipment_seq shipseq     
        JOIN shipment_line shipline ON shipline.shipment_id = shipseq.shipment_id AND shipline.shipment_line = shipseq.shipment_line    
        JOIN pick_list_ref picklistref ON picklistref.pick_list_id = shipline.pick_list_id AND picklistref.sequence = shipline.pick_list_ref_sequence    
        JOIN coitem coitem ON coitem.co_num = picklistref.ref_num AND coitem.co_line = picklistref.ref_line_suf AND coitem.co_release = picklistref.ref_release AND picklistref.ref_type = 'O'    
        JOIN shipment ship ON ship.shipment_id = shipseq.shipment_id AND ship.status <> 'S'    
      WHERE coitem.co_num     = @CoNum AND    
            coitem.co_line    = @ConvCoLine AND    
            coitem.co_release = @ConvCoRelease    
             
   SET @pick_pack_ship_qty = ISNULL(@qty_to_pick,0) + ISNULL(@qty_picked,0) + ISNULL(@qty_to_ship,0)    
       
   IF  @pick_pack_ship_qty > 0    
   BEGIN    
      UPDATE #w_coitem     
      SET qty_to_pack_conv= qty_ordered - ISNULL(@pckitem_qty_packed,0) - ISNULL(@pick_pack_ship_qty,0)       
           ,qty_to_pack = qty_ordered - ISNULL(@pckitem_qty_packed,0) - ISNULL(@pick_pack_ship_qty,0)    
           ,max_qty_to_pack_conv=qty_ordered - ISNULL(@pckitem_qty_packed,0) - ISNULL(@pick_pack_ship_qty,0)    
      WHERE #w_coitem.co_line    = @ConvCoLine    
        AND #w_coitem.co_release = @ConvCoRelease    
   END    
       
END    
    
SELECT    
  co_line    
, co_release    
, qty_packed    
, qty_to_pack    
, qty_to_pack_conv    
, max_qty_to_pack_conv    
, qty_ordered    
, qty_ordered_conv    
, u_m    
, item    
, item_desc   
, item_um    
, 1 AS print_line    
, qty_invoiced    
, qty_shipped    
FROM #w_coitem    
ORDER BY co_line, co_release    
    
RETURN 0
GO


