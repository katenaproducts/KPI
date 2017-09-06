USE [KPI_App]
GO

/****** Object:  StoredProcedure [dbo].[EXTGEN_COShippingTrxPostSp]    Script Date: 08/30/2017 15:48:14 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



/* $Header: /ApplicationDB/Stored Procedures/COShippingTrxPostSp.sp 186   2/02/16 1:35p pgross $ */
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
*   (c) COPYRIGHT 2011 INFOR.  ALL RIGHTS RESERVED.           *
*   THE WORD AND DESIGN MARKS SET FORTH HEREIN ARE            *
*   TRADEMARKS AND/OR REGISTERED TRADEMARKS OF INFOR          *
*   AND/OR ITS AFFILIATES AND SUBSIDIARIES. ALL RIGHTS        *
*   RESERVED.  ALL OTHER TRADEMARKS LISTED HEREIN ARE         *
*   THE PROPERTY OF THEIR RESPECTIVE OWNERS.                  *
*                                                             *
***************************************************************
*/
/* $Archive: /ApplicationDB/Stored Procedures/COShippingTrxPostSp.sp $
 *
 * SL9.00.30 186 205712 pgross Tue Feb 02 13:35:03 2016
 * LIFO/FIFO stack cost is incorrect when perform co shipment that has 'Shipment Approval Required' is ticked
 * match itemlifo records using the inventory accounts instead of in-process accounts
 *
 * SL9.00.30 185 204380 Lzhan Thu Nov 26 00:47:35 2015
 * Serial number returned from CO does not appear on Reservations for Orders form
 * Issue 204380: when set rsvd_num= 0, it should be NULL.
 *
 * SL9.00.30 184 203667 Cliu Mon Nov 16 02:53:26 2015
 * Out of inventory serials can appear on unposted job transactions and be changed back to In Inventory
 * Issue:203667
 * Remove the logic to update the transaction number in serial table.
 *
 * SL9.00 183 201473 Shu Tue Sep 01 22:49:21 2015
 * 'Change Status to Open' doesn't work correctly
 * Issue 201473: Remove redundant statement.
 *
 * SL9.00 182 201473 Shu Tue Sep 01 06:22:46 2015
 * 'Change Status to Open' doesn't work correctly
 * Issue 201473: Update @CoitemQtyPicked and @CoitemQtyPacked, when it's unshipped by Unshipment form and not return to stock, the qty should remain.
 *
 * SL9.00 180 199306 pgross Wed Aug 05 12:18:06 2015
 * Currency code is different when co ship and return
 * return costs are now based upon co_ship information
 *
 * SL9.00 179 196232 pgross Mon Jun 15 16:13:47 2015
 * After shipping and unshipping via negative shipment a Non-Inventory Item, the Qty Ready is set to -1
 * do not allow qty ready to be negative for non-inventory items
 *
 * SL9.00 178 195514 pgross Thu May 28 15:38:20 2015
 * Performing a shipment against one order also unreserves the second serial and changes its reference to the other order.
 * include joining on item when also joining on ser_num
 *
 * SL9.00 177 194780 pgross Mon May 11 11:14:33 2015
 * Need better error message
 * do not ignore error messages coming from CurrCnvtSp
 *
 * SL9.00 176 193433 Ltaylor2 Mon Apr 13 09:33:59 2015
 * Serial tracked items shipped through Pick Pack Ship and returned through Order Shipping can not be shipped via Pick Pack Ship again
 * Issue 193433 - Set serial.assigned_to_be_picked = 0
 *
 * SL9.00 175 192117 pgross Mon Mar 16 10:53:44 2015
 * EU Sales List Report includes invoice data for shipments from non EU locations to EU destination countries.
 * do not create an SSD when the source or destination is not an EU country
 *
 * SL9.00 174 192029 pgross Wed Mar 04 16:28:42 2015
 * CO-PO Automation - Need better error message when there is a problem with shipment
 * capture errors coming from DemandingPoSourceCoSyncSp
 *
 * SL9.00 173 189725 Ltaylor2 Mon Feb 16 11:30:54 2015
 * Unable to create a new Packing Slip for a CO Line that has been Shipped, Returned and Shipped again.
 * Issue 189725 - This is a backout of issue 179379, which should be addressed by RS7221
 *
 * SL9.00 172 191157 pgross Fri Feb 13 15:28:04 2015
 * No EU SSD dispatch record is created after a customer order for a customer based in the EU has been shipped via Order Shipping
 * corrected SSD border detection
 *
 * SL9.00 171 181874 pgross Fri Aug 08 17:10:58 2014
 * Duplicate EU SSD transaction generated from order shipping after working through the inventory consigned to customer process
 * only create ssd records when crossing a border
 *
 * SL9.00 170 181990 Dyang2 Mon Jul 28 03:01:34 2014
 * Pick List Quantity not reset after Unship performed
 * Issue 181990: Update coitem.qty_picked value when unship CO with shipment Id.
 *
 * SL9.00 169 179379 Dyang2 Mon Jul 21 11:15:46 2014
 * Qty Packed on CO Lines form is updated after return process without Packing Slip.
 * Issue 179379: Only update CO Qty Packed value when shipment has package record or packing slip number provided for this CO.
 *
 * SL9.00 168 179504 Cliu Wed Jul 02 02:40:09 2014
 * Cannot process Credit Return through Order Shipping after using Pick/Pack/Ship and Consolidated Invoicing.
 * Issue:179504
 * Change to use message "E=IsCompare>3Or1" instead of "E=IsCompare>3".
 *
 * SL9.00 167 179576 Djackson Tue Jul 01 08:40:41 2014
 * RS5618 coding and schema
 * WM - 179576
 *
 * SL9.00 166 175049 calagappan Thu May 15 17:00:06 2014
 * Time stamp on co shipment always showing 12:00 am
 * Use accurate transaction date and time
 *
 * SL9.00 165 177724 pgross Wed Apr 02 11:26:07 2014
 * When processing a customer order return (either negative or CR return) the EU SSD return transaction does not populate the Suppl Units field correctly.
 * populate suppl_qty on returns
 *
 * SL9.00 164 177584 pgross Tue Apr 01 13:28:03 2014
 * The Transport Mode is not filled in on the EU SSDs form even though the Ship Via Code is defined on the warehouse record when shipping a customer order blanket release
 * search additional places for a transport code
 *
 * SL9.00 163 174911 pgross Wed Mar 19 13:28:06 2014
 * The Accum CO Value and Accum Shipped Value fields are not updating correctly on the Customer Letters of Credit form when processing a Customer Order
 * update LCR order_accum with tax amounts
 *
 * SL9.00 162 171639 Ltaylor2 Tue Jan 28 15:19:14 2014
 * Error pop up when return goods on Order shipping
 * Issue 171639 - Added ISNULL(,0) around entire section that sums co_ship_approval_log records - if there are no records it was returning NULL causing the issue
 *
 * SL9.00 161 172010 Lchen3 Wed Nov 20 21:10:42 2013
 * Pick List Status not changing from Packed to Shipped after shipping
 * issue 172010
 * change the status of pick list to shipped only when it is in Packed status while shipping a shipment.
 *
 * SL9.00 160 170586 Lchen3 Mon Oct 28 01:48:21 2013
 * Ship Confirmation Duplicated
 * issue 170586
 * Don't update the status in post sp
 *
 * SL9.00 159 170862 Lchen3 Sun Oct 27 22:27:39 2013
 * CO Line Picked Qty incorrect if Unpack\Unpick process incomplete before Shipping
 * issue 170862
 * While doing a shipment confirmation, change the status of pick list to "Shipped" only when it is "Packed".
 *
 * SL8.04 158 167049 Jsun Fri Aug 30 05:25:11 2013
 * The system doesn't validate the approved qty
 * Issue 167049: Adjusted the format.
 *
 * SL8.04 157 167049 Jsun Fri Aug 30 05:09:56 2013
 * The system doesn't validate the approved qty
 * Issue 167049: Removed Tab keys in my previous logic.
 *
 * SL8.04 156 167049 Jsun Fri Aug 30 04:26:38 2013
 * The system doesn't validate the approved qty
 * Issue 167049: Declared a new variable @CoShipQtyApproved with QtyUnitType, and added the new logic to handle with the approved qty when doing un-shipping process.
 *
 * SL8.04 155 167885 pgross Wed Aug 28 16:15:53 2013
 * Invoice Register Report shows wrong cost information for Non- Inventory item X-Ref'd to Purchase Order.
 * assign a unit cost to co_ship.cost for non-inventory items
 *
 * SL8.04 154 166970 calagappan Tue Aug 20 16:52:36 2013
 * Credit Memo will not generate when going a Credit Return on a lot- tracked item.
 * Traverse co_ship table to identify rows to update during returns
 *
 * SL8.04 153 166970 Lchen3 Wed Aug 14 03:08:29 2013
 * Credit Memo will not generate when going a Credit Return on a lot- tracked item.
 * ISSUE 166970
 * check the @coshiprowpoint instead of the @@rowcount after load the rowpoint with mattrack records.
 *
 * SL8.04 152 165060 Lchen3 Wed Jul 17 05:30:58 2013
 * When a CO is unship and reship using a different lot, the invoice amount is double
 * ISSUE 165060
 * Ingore the lot value if there no match co_ship reocrds.
 * Update the last co_ship records.
 *
 * SL8.04 151 RS5183 Djackson Wed Jul 10 14:11:08 2013
 * RS5183 - AutoConnect
 *
 * SL8.04 150 164393 pgross Mon Jul 01 11:46:41 2013
 * Slow Performance on Ship Confirmation
 * restrict pick_list update by shipment ID
 *
 * SL8.04 149 159127 Dmcwhorter Mon Jul 01 11:05:16 2013
 * Price rounding is incorrect on Customer order lines as it multiplies by qty ordered before rounding
 * RS6172 - Alternate Net Price Calculation.
 *
 * SL8.04 147 158216 Lliu Sat Jun 08 04:20:17 2013
 * Some items can't be shipped successfully.
 * Issue 158216: Check the message has the same style.
 *
 * SL8.04 145 162419 Lchen3 Fri May 17 02:20:13 2013
 * shipment value field does not include order line discount
 * issue 162419
 * add the calculate of discount on line and order.
 *
 * SL8.04 142 161505 Lchen3 Thu Apr 25 03:13:52 2013
 * Shipment Value in Shipment Master shows incorrect amount when status = Shipped.
 * issue161505
 * clear the shipment value before ship and recalculate it in TrxPostSP.
 * use a temp table to record the shipmentId which had cleaned the shipment value already.
 *
 * SL8.04 141 159321 pgross Wed Apr 17 16:48:21 2013
 * wrong lot in Delivery Order Line Sequences
 * match on Lot when searching for a co_ship for returns
 *
 * SL8.04 140 160955 Jmtao Wed Apr 17 01:18:44 2013
 * Remove Inventory Adjustment In Process accounts
 * 160955 Remove logic from COShippingTrxPostSp, it should always use the regular inventory adjustment account.
 *
 * SL8.04 139 158963 pgross Wed Mar 06 15:32:28 2013
 * DO Line Sequence not updated properly when performed CO Return
 * match on CO line/release when searching for the latest do_seq for a return
 *
 * SL8.04 138 159204 pgross Wed Mar 06 10:01:39 2013
 * use extended amount of converted quantity instead of base U/M quantity
 *
 * SL8.04 137 153878 calagappan Thu Jan 24 17:31:54 2013
 * When using preship packing slip and printing multiple preships, then ship & unship a qty, packed qty is zeroed out
 * On returns decrease coitem.qty_packed by returned quantity up to 0
 *
 * SL8.04 136 RS3377 Dlai Tue Jan 15 02:43:29 2013
 * RS337 Change back from UMConvFactor2Type to UMConvFactorType
 *
 * SL8.04 135 156770 pgross Fri Dec 21 11:40:37 2012
 * Quantity Returned is greater than (Blank) for CO Shipment that has [DO:(Blank)] and [DO Line:0] error when doing negative ship transaction.
 * added packing slip to the negative qty error message
 *
 * SL8.04 134 154468 Clarsco Fri Dec 14 14:22:29 2012
 * Incorrect pckitem.qty_packed after reversing a shipment
 * Fixed Issue 154468
 * Moved UPDATE pckitem outside of WHILE loop.
 *
 * SL8.04 133 154916 Lchen3 Mon Nov 26 00:56:54 2012
 * issue 154916
 * modify for negitave order shipping
 *
 * SL8.04 132 RS5421 Ezi Fri Nov 23 03:08:37 2012
 * RS5421 - Update inv_num in table co_ship_approval_log when CR return = 1 and Qty > 0.
 *
 * SL8.04 131 155556 Lchen3 Wed Nov 21 22:25:41 2012
 * CO ?PO Automation; if an item is NOT lot tracked in the Demand Site but is Lot tracked in the source site Auto Receive is not allowed.
 * issue 155556
 * get lot/serial tracked parameters form all table when check linked order
 *
 * SL8.04 130 155174 Lchen3 Wed Nov 21 00:57:26 2012
 * Cannot perform negative shipment if there has been a packing slip printed
 * issue 155174
 * Remove the extra condition "and isnull(co_ship.pack_num, 0) = isnull(@PackNum, 0)" in COShippingTrxPostSp.
 *
 * SL8.04 129 RS5421 Ezi Fri Nov 16 04:46:03 2012
 * RS5421 - Insert negitive approve amount to approve log table when credit return.
 *
 * SL8.04 128 RS5421 Ezi Fri Nov 09 00:23:56 2012
 * RS5421 - Correct some errors
 *
 * SL8.04 127 RS5421 Ezi Fri Nov 09 00:05:44 2012
 * RS5421 - Add product code in process account
 *
 * SL8.04 126 RS5421 Ezi Thu Nov 08 00:41:10 2012
 * RS5421 - Remove function GetNegShipmentQty and add calculating @TAdjQty logic.
 *
 * SL8.04 125 RS5421 Ezi Wed Nov 07 07:21:35 2012
 * RS5421 - IFRS - Customer shipment approval
 * Enhancement:
 * 1.)   Enhance section for negative quantities to filter records where SUM(co_ship_approval_log.qty_approved) = co_ship.qty_shipped.
 * 2.)   Assign accounts and unit codes from endtype if it exists if not then use distacct  for cgs_in_proc_matl_acct, cgs_in_proc_lbr_acct, cgs_in_proc_fovhd_acct, cgs_in_proc_vovhd_acct and cgs_in_proc_out_acct to @TCgsAcct, @TCgsLbrAcct, @TCgsFovhdAcct, @TCgsVovhdAcct and @TCgsOutAcct.
 * 3.)   Assign Inventory accounts and unit codes to the Inventory In Process accounts when the customer order Shipment Approval Required is checked.
 * For negative quantity shipments, when customer.shipment_approval_required is one (checked), ensure that co_ship.ship_date matches the date value for TransDate
 *
 * SL8.04 124 RS5421 Ezi Tue Nov 06 06:33:49 2012
 * RS5421 - IFRS - Customer shipment approval
 *
 * SL8.04 123 152522 Sxu Thu Sep 13 23:23:12 2012
 * Poor performance due to table scan
 * Issue 152522 - Add condition "AND poitem_all.po_release = serial_all.ref_release" when @ItemSerialTracked=1
 *
 * SL8.04 122 152516 pgross Mon Aug 27 16:53:38 2012
 * Quantity Returned is greater than 0.00000000 for CO Shipment that has [DO: (Blank)] and [Do Line: 0] when running negative Order Shipping
 * corrected available quantity check
 *
 * SL8.04 121 152388 pgross Fri Aug 24 09:23:42 2012
 * Co Released Status not be 'Filled' after perform a shipment with full Quantity.
 * ignore minor rounding differences between quantity shipped and ordered
 *
 * SL8.04 120 151585 Ltaylor2 Wed Aug 22 15:53:24 2012
 * The data doesn't display correctly in the Inventory grid in the form 'Pick Workbench'
 * Issue 151585 - always update itemloc
 *
 * SL8.04 119 135457 Bbai Thu Aug 16 02:57:30 2012
 * A message pops up when trying displaying a record has a large quantity over 10 digits to the left of the decimal with negative sign.
 * Issue 135457:
 * Change QtyPerType to QtyUnitType.
 *
 * SL8.04 118 152105 Ltaylor2 Mon Aug 13 16:48:14 2012
 * Unable to ship the rest of packages in a shipment
 * Issue 152105 - not updating shipment_seq or shipment_seq_serial records properly
 *
 * SL8.04 117 151767 Ltaylor2 Wed Aug 01 07:46:41 2012
 * The field ?Shipment Value?is showing an incorrect value
 * Issue 151767 - shipment value doubling
 *
 * SL8.04 116 151008 pgross Thu Jul 19 14:44:30 2012
 * If there's a CO return with Packing Slip on a line, the Packing Slip Selection Modal won't come up with the other co shipment data on that line
 * decrement qty packed on overshipment returns
 *
 * SL8.03 115 146452 Ddeng Sun Jun 03 23:33:40 2012
 * Issue fro RS 5397 implementation of PO-CO Automation
 * Issue 146452: Fix the join condition for Serial validation.
 *
 * SL8.03 114 149775 Ddeng Thu May 31 11:21:36 2012
 * Codes Review: RS5397 Auto Create PO-CO Across Sites
 * Issue 149775: fix the validations for serial and lot when doing auto po/co on demanding site.
 *
 * SL8.03 113 149775 csun Thu May 31 05:32:30 2012
 * Codes Review: RS5397 Auto Create PO-CO Across Sites
 * Issue:149775
 * Delete parameter @PoAllSourceSiteCoNum, replaced with existed parameter @SCoNum
 *
 * SL8.03 112 146452 Lchen3 Tue May 29 21:50:54 2012
 * Issue fro RS 5397 implementation of PO-CO Automation
 * RS 5397
 * ISSUE 146452
 * do not consider negative quantity auto return this time.
 *
 * SL8.03 111 146452 Lchen3 Tue May 29 02:50:05 2012
 * Issue fro RS 5397 implementation of PO-CO Automation
 * rs5397
 * issue 146452
 * add parameters while call DemandingPoSourceCoSyncSp
 *
 * SL8.03 110 146452 Lchen3 Thu May 24 21:18:35 2012
 * Issue fro RS 5397 implementation of PO-CO Automation
 * rs5397
 * issue 146452
 * add infobar parameters while call DemandingPoSourceCoSyncSp
 *
 * SL8.03 109 148119 Ltaylor2 Thu May 24 12:54:41 2012
 * 5325 - Pack and Ship design coding
 * Added shipment_id parameter.  Set co_ship.shipment_id, set serial.shipment_id.  Update shipment info.  Update pick_list
 *
 * SL8.03 108 146452 Mewing Mon Apr 16 10:21:54 2012
 * Auto Create Co from Po from different site
 *
 * SL8.03 107 147406 Bli2 Mon Mar 12 05:48:05 2012
 * Total Cost amount is not correct
 * Issue 147406 - Use coitemcost form co_ship material cost.
 *
 * SL8.03 106 145299 Clarsco Tue Mar 06 16:53:19 2012
 * When a CO line is shipped and returned against multiple DO lines the quantity shipped can be incorrect.
 * Fixed Issue 145299
 * Add WHERE clause for DO?s to a SELECT co_ship that finds the unique do_seq for the primary SELECT co_ship with UPDLOCK.
 *
 * SL8.03 105 134983 pgross Wed Jan 25 14:05:51 2012
 * replaced UMConvFactorType with UMConvFactor2Type
 *
 * SL8.03 104 145543 pgross Tue Dec 20 11:31:27 2011
 * Error when shipping a non-inventory item.
 * do not generate an error about a missing distacct when the cost is zero
 *
 * SL8.03 103 144644 Mmarsolo Fri Nov 04 14:00:54 2011
 * Journal entries are not being created, cost is not being recorded for non-inv items
 * 144644 - Updated handling of non-inventory items.  Changed costing, inventory accounts, and journal posting logic.
 *
 * SL8.03 102 143037 Jgao1 Sun Oct 09 03:22:22 2011
 * Total Cost field is blank on the Order Shipped Cost Report for non inventory items.
 * 143037
 *
 * SL8.03 101 143151 sturney Mon Sep 26 09:41:12 2011
 * Does not correctly validate available quantity for a Negative CR Return
 * Issue 143151  Added logic to update reserved quantities for negative CR Return transaction.
 *
 * SL8.03 100 142079 Mmarsolo Wed Aug 31 11:30:29 2011
 * Can't ship serial tracked item if multiple items have the same S/N
 * 142079 - Add Item to serial select in tmp_ser_crs
 *
 * SL8.03 99 138039 chuang2 Tue Aug 09 04:50:02 2011
 * Can't ship Non-Inventory Items.
 * Issue 138039
 * Indent the added codes.
 *
 * SL8.03 98 138039 chuang2 Tue Aug 09 02:57:15 2011
 * Can't ship Non-Inventory Items.
 * Issue 138039
 * Allow ship Non-Inventory Item which Source is set to Inventory.
 *
 * SL8.03 97 140476 Ddeng Wed Jul 27 02:56:39 2011
 * Unable to post Shipping Transaction Type
 * Issue 140476 Set null to @ContainerNum in case other callsers does not have @ContainerNum.
 *
 * SL8.03 96 139418 Jgao1 Fri Jul 22 05:07:14 2011
 * The Unit Cost field resets to 0.00 when you ship a Customer Order for a Non Inventory Item.
 * 139418: Add condition @nooinventory
 *
 * SL8.03 95 139918 calagappan Mon Jul 11 17:58:17 2011
 * The SSD Value on the EU SSD form is incorrect after running Order Shipping
 * store extended shipping price in SSD table
 *
 * SL8.03 94 RS4892 Bli2 Fri Jun 03 05:01:50 2011
 * RS4892 - if shipping by container, remove container at first
 *
 * SL8.03 93 137377 Jgao1 Fri May 13 04:44:47 2011
 * Stored Procedures need to be cleaned up
 * IS137377 : Some block of code was indented. Delete a line code that was commented out
 *
 * SL8.03 92 RS3639 chuang2 Wed Mar 09 02:26:29 2011
 * RS3639 Modify the logic so that a Null ItemRowPointer does not cause an error. If the ItemRowpointer is Null, skip the product code validation and itemwhse checks.  Skip itemloc section for returning items to stock.  Skip the costing section and create a new one for non-inventory items.  Costs will just be the cost amount on the coitem record multiplied by the shipping qty.  Create matltran_amt records 1 and 2 similar to what is done for the current transactions.
 * For the COGS account posting the coitem cost amount will be recorded against the COGS Material Account, the other accounts will not have any costs associated with them.  The INV account posting will then use the same cost amount and use the account specified on the CO line.
 *
 * SL8.03 91 RS3384 Ezi Wed Feb 23 21:10:21 2011
 * RS3384 - Transaction User Initials
 *
 * SL8.03 90 133158 pgross Thu Oct 07 16:56:39 2010
 * Serial Number does not show on Credit Note and re Invoice
 * do not reset reference information on serial record when returning material
 *
 * SL8.03 89 132627 flagatta Wed Sep 01 14:54:02 2010
 * Make VAT enhancements per RS4916
 * Do not create ssd if Process Indicator = 3. (RS4916)  132627
 *
 * SL8.03 88 131921 Bli2 Fri Jul 23 05:42:36 2010
 * Cost data not properly updated when shipping a line
 * Issue 131921
 * Calculate the cost_conv and update to coitem.
 *
 * SL8.02 87 130495 flagatta Mon May 24 10:35:49 2010
 * COShippingTrxPostSp needs revisited regarding Costing at item warehouse
 * If costing at whse, update itemwhse costs.  Also, fixed an insert into itemlifo. 130495
 *
 * SL8.02 86 127470 calagappan Mon May 17 14:12:55 2010
 * Running the EU Supplementary Statistical Declaration (SSD) Report for a transaction where the commodity code does not require Suppl Units to be calculated, the report will display a value when it should display a 0.
 * Calculate EU SSD?s Suppl Unit value only when Commodity Code Suppl Units Required flag is on
 *
 * SL8.02 85 129036 Vlitmano Mon Apr 19 15:33:11 2010
 * Receiving a LIFO item into inventory populates the warehouse field
 * 129036 - updated an insert to 'itemlifo' table to only include a whse if 'Cost Item At Whse' parameter is selected.
 *
 * SL8.02 84 rs4494 Dahn Thu Apr 01 13:53:01 2010
 * rs4494 - if invparms.cost_item_at_whse is set to 1, then use the itemwhse table instead of item using the coitem.whse (@CoitemWhse).
 * - if invparms.cost_item_at_whse is set to 1, then include the whse when accessing the itemlifo table, using the itemloc warehouse.  Otherwise, the warehouse should be null for itemlifo.
 *
 * SL8.02 83 rs4588 Dahn Thu Mar 04 10:28:23 2010
 * RS4588 Copyright header changes
 *
 * SL8.02 82 rs4588 Dahn Thu Mar 04 09:38:42 2010
 * RS4588 Copyright header changes
 *
 * SL8.02 81 126745 Dmcwhorter Fri Jan 29 14:35:55 2010
 * CO returns are being done at the average cost of the shipments for specific costed, lot tracked items
 * 126745 - For negative shipping transactions of lot tracked items using Actual/Specific costing, attempt to return at the cost originally shipped at.
 *
 * SL8.02 80 125856 pgross Wed Nov 25 15:19:26 2009
 * Order Shipment record still exists after perform Order Shipping negative reverse entry.
 * when searching for a do_seq value, also match on do_num and do_line
 *
 * SL8.02 79 121361 Mewing Mon Oct 12 14:51:24 2009
 * SL8.02 00 121361  All references to BatchId2Type need to be changed back to BatchIdType.  This checkin will affect stored procedures, triggers, functions.
 * Schema, property classes and component classes will be done seperately.
 *
 * SL8.01 78 123340 pgross Wed Sep 09 11:21:03 2009
 * Unit Cost is incorrect for Customer Order Lines after shipping
 * delay rounding until the costs are assigned to matltran
 *
 * SL8.01 77 121790 pgross Wed Jun 17 15:27:25 2009
 * On the Purchase Order Line the SSD Value under the EC VAT tab is not updated if the material cost is amended
 * do not multiply the Export Value by the quantity
 *
 * SL8.01 76 118985 Cajones Mon May 18 15:04:38 2009
 * Issue:118985,APAR:115322 - Changed references of type BatchIdType (defined as tinyint) to new UDDT BatchId2Type (defined as int).  This change is to allow the user to enter a 6 digit batch id number.
 *
 * SL8.01 75 117398 pgross Tue Feb 10 16:04:21 2009
 * Delivery Order Sequence is not being removed during a negative shipment if item is serial tracked
 * allow for Lot to be NULL when looking for matltrack records
 *
 * SL8.01 74 116670 pgross Thu Jan 08 17:26:54 2009
 * Journal entries from order shipping leaving gaps in control numbers in the journal
 * do not consume a Control Number if all costs are zero
 *
 * SL8.01 73 113597 pgross Tue Dec 16 09:50:01 2008
 * Purchase Order Receiving -  Using wrong stacks when processing a negative Receipt
 * prevent creation of itemlifo records with duplicate dates
 *
 * SL8.01 72 114004 pgross Mon Dec 08 13:36:29 2008
 * Cannot print Credit Memo
 * match do_num on returns
 *
 * SL8.01 71 113824 pgross Wed Oct 08 16:09:25 2008
 * Incorrect invoice amt when perform a partail shipping and refer to Progressive Billing.
 * do not update the customer balance when updating the coitem
 *
 * SL8.01 70 113441 bpettit Mon Sep 08 17:05:29 2008
 * Syteline locks up if you try to ship customer order where customer is on credit hold and ship is thru Shipping Processing Orders form
 * 113441 - @Severity not set on CreditCheck failure - Causing infinite loop
 *
 * SL8.01 69 113580 bpettit Fri Sep 05 13:18:38 2008
 * Unit Weight not updating on Customer Order Lines
 * 113580 - Unit Weight not updating on Customer Order Lines
 *
 * SL8.01 68 rs3953 Vlitmano Tue Aug 26 16:43:37 2008
 * RS3953 - Changed a Copyright header?
 *
 * SL8.01 67 rs3953 Vlitmano Mon Aug 18 15:08:39 2008
 * Changed a Copyright header information(RS3959)
 *
 * SL8.01 66 108517 Djackson1 Mon Aug 04 15:45:10 2008
 * Serial Table is not being Updated on changes to various values
 * 108517 - Serial Number ref number update
 *
 * SL8.01 65 110167 nmannam Wed Jul 30 02:37:26 2008
 * Quantity Ready is incorrect on Customer Order lines
 * 110167-if the ref_type is other than Inventory and the ref_num is blank the quantity ready should not be updated .
 *
 * SL8.01 64 109998 rbathula Fri Jul 04 02:37:53 2008
 * Delivery Order Lines -  the value field total value displayed is rounded differently than the value for the consolidated invoice.
 * Solving Issue:109998
 * @DoHdrDoValue rounded
 *
 * SL8.01 63 108767 akottapp Mon Apr 21 04:18:56 2008
 * Delivery Order Sequence is not being removed during a negative shipment.
 * Issue 108767
 * Set value for @CoShipDoSeq variable if there are no records exist in matltrack table for a customer order.
 *
 * SL8.01 62 108058 nmannam Fri Apr 04 02:46:32 2008
 * The CO dist journal entry for CO return is not correct for Actual/Specific/Lot tracked item.
 * 108058-Before updating lot_loc table,SkipItemLotLocPostSave' set to 1 to skip the posting of journals into 'IC DIST' in ItemLotLocPostSave called in lot_lociup trigger.
 *
 * SL8.01 61 108501 nmannam Tue Mar 25 04:53:26 2008
 * Error message and not able to ship Reserved item: "Procedure or Function 'UpdResvSp' expects parameter '@SessionID', which was not supplied."
 * 108501- sessionid is passed to 'UpdResvSp'.
 *
 * SL8.00 60 104881 Dmcwhorter Tue Aug 28 15:30:06 2007
 * Shipping tab showing wrong value in Packed field after processing a return trx
 * 104881 - Correct assignment of coitem.qty_packed.
 *
 * SL8.00 59 100019 Hcl-ajain Wed Mar 07 05:29:28 2007
 * Customer Order Line will not print on the To Be Invoiced Report
 * Issue # 100019
 * Changed logic for assigning the last ship date in Coitem table.
 *
 * SL8.00 58 99945 hcl-jmishra Fri Mar 02 06:11:13 2007
 * Cannot print Credit Memo if Credit Return was performed against a location with negative on hand
 * Issue 99945
 * Updated where clause of query that fetched ship to detail.
 * co_ship.do_seq=ISNULL(@CoShipDoSeq,0)
 *
 * SL8.00 57 rs2968 nkaleel Fri Feb 23 01:12:14 2007
 * changing copyright information
 *
 * SL8.00 56 99612 pgross Tue Feb 20 09:18:48 2007
 * unable to post overshipment
 * removed  invalid parameters to GetCoitemLinePriceSp
 *
 * SL8.00 55 98714 hcl-jmishra Thu Feb 08 01:58:25 2007
 * Delivery order return using lots doesnt affect the correct sequence
 * Issue #98714
 * Modified the code of the SP so as to get correct delivery order sequence during Order Shipping
 *
 * SL8.00 54 98847 pgross Fri Jan 26 15:37:41 2007
 * On Order Balance incorrect when do the RMA Credit against the fully shipment order
 * adjust customer.order_bal on overshipments
 *
 * SL8.00 53 97346 Clarsco Mon Oct 23 09:33:51 2006
 * Application Lock failurer fails to stop process
 * Fixed Bug 97346
 * Added @Severity Trap following NextControlNumberSp call.
 *
 * SL8.00 52 97227 Hcl-ajain Fri Oct 13 10:27:28 2006
 * CO return on DC give error message Quantity Returned is greater than (Blank) for CO Shipment that has [DO: (Blank)] and [Do Line:   0]
 * Issue # 97227
 * 1. Changed Nchar(1) to ''
 *        i.e
 *        isnull(co_ship.do_num, '') = isnull(@SDoNum, '') and
 *             ISNULL(co_ship.do_line,'') = ISNULL(@SDoLine,'')
 * while querying .
 *
 * SL8.00 51 92432 binesh.chandran Wed Aug 23 01:07:23 2006
 * Currency conversion failures have no message.
 * Issue No : 92432, Added "@Severity" check for calls to CurrCnvtSp
 *
 * SL8.00 50 95591 hcl-nautami Fri Aug 18 11:25:07 2006
 * When print a range of orders,  the system stop when hits an order for a customer on credit hold
 * Issue 95591:
 * Added a new output parameter @CredHold to the Sp and returned the value of credit hold in this paramter.
 *
 * SL8.00 49 RS2968 prahaladarao.hs Thu Jul 13 02:47:06 2006
 * RS 2968, Name change CopyRight Update.
 *
 * SL8.00 48 RS2968 prahaladarao.hs Tue Jul 11 05:48:36 2006
 * RS 2968
 * Name change CopyRight Update.
 *
 * SL8.00 47 95128 Hcl-sharpar Wed Jul 05 10:15:17 2006
 * Incorrect quantity in Customer Order Lines Form "Ready" field
 * Issue 95128
 * Added the code to reassign value to variable @CoitemQtyRsvd.
 *
 * SL8.00 46 94496 pgross Tue May 30 09:02:06 2006
 * DC background process shutdown with the error message "The item entered cannot be null in itemlifo.  INSERT rolled back" in the collect.err
 * allow ItemLocCheckSp to create itemloc records
 *
 * SL8.00 45 93862 Hcl-ajain Fri Apr 21 06:43:04 2006
 * CO Line status not changing when entire qty has been shipped and u/m conversion on line
 * Issue # 93862
 * Reverting back the changes done for issue # 84787
 *
 * SL8.00 44 93862 Hcl-ajain Fri Apr 21 06:12:03 2006
 * CO Line status not changing when entire qty has been shipped and u/m conversion on line
 * Issue # 93862
 * Reverting back the changes done for issue # 84787
 *
 * SL8.00 43 93619 Clarsco Tue Apr 18 14:33:10 2006
 * Cannot add a shipment that has been posted through data collection to a Delivery Order
 * Fixed Bug 93619:
 * Bullet Proofed @STransDate by setting time to midnight and checking for NULL.
 *
 * SL7.05 42 90206 NThurn Tue Jan 31 20:37:35 2006
 * Do not use SCOPE_IDENTITY() with INSTEAD OF INSERT triggers.  (RS3158)
 *
 * SL8.00 41 90252 pgross Fri Jan 13 09:53:35 2006
 * EDI import of shippers - Performance is slow in co shipping error processing form
 * allow skipping of credit check
 *
 * SL8.00 40 91818 NThurn Mon Jan 09 09:58:12 2006
 * Inserted standard External Touch Point call.  (RS3177)
 *
 * SL7.05 39 91123 hcl-singnee Wed Dec 14 23:56:41 2005
 * 0129 dbo.ExpandKy() shouldn't be used directly
 * Issue# 91123
 * Now dbo.ExpandKy() function is called only through other ExpandKy* functions.
 *
 * SL7.05 38 90199 Hcl-mehtviv Fri Oct 28 03:54:18 2005
 * "Accum Shipper Values" show incorrect amount after process a CO-return
 * Issue  90199:
 * Added condition to check for CR Return. If condition is true and quantity greater than 0, Shipped Value  is subtracted from previous value else added.
 *
 * SL7.04 37 90018 Hcl-purosan Fri Oct 28 02:27:18 2005
 * Unit Cost on Items form is not correct for FIFO item after series of transactions
 * Issue 90018
 * Updated the Item cost when there is a return from order shipping and there is no record in item lifo.
 *
 * SL7.04 36 88886 Hcl-kannvai Fri Sep 02 10:20:09 2005
 * Order shipping will yield error when have items where unit of measure conversion exists and items are serial tracked.
 * Checked in for Issue #88886.
 * Declared um and conversion variables and logic to convert the quantity using conversion factor based on the new UM. It is used to compare with tmp_ser table count value for proper quantity comparison.
 *
 * SL7.04 34 88510 Debmcw Thu Aug 04 18:05:17 2005
 * Apply SL705 RS to SL703 & SL704
 * RS 2830
 *
 * SL7.05 34 RS2830 hcl-nautami Tue Aug 02 07:01:40 2005
 * RS 2830
 *
 * SL7.05 33 87424 Hcl-kavimah Thu May 26 07:57:19 2005
 * CO return linked to delivery order gives Error message [Post] was not successful for Pending CO shipping transaction that has [order xx ] and [line xx] and [release xx].
 * Issue 87424,
 *
 * removed the DO checking conditions whenever CR flag is checked
 *
 * SL7.04 33 87424 Hcl-kavimah Thu May 26 07:54:19 2005
 * CO return linked to delivery order gives Error message [Post] was not successful for Pending CO shipping transaction that has [order xx ] and [line xx] and [release xx].
 * Issue 87424,
 *
 * removed the DO checking conditions whenever CR flag is checked
 *
 * $NoKeywords: $
 */
 
 -- 06/22/17
 -- Modified to assign Matltran Number on the Serial Record  
CREATE PROCEDURE [dbo].[EXTGEN_COShippingTrxPostSp] (
  @SCoNum      CoNumType
, @SCoLine     CoLineType
, @SCoRel      CoReleaseType
, @SDoNum      DoNumType
, @SDoLine     DoLineType
, @SLoc        LocType
, @SLot        LotType
, @OKtoCreateLotLoc ListYesNoType = 0
, @SItem       ItemType
, @SQty        QtyUnitNoNegType
, @SReturn     ListYesNoType
, @SRetToStock ListYesNoType
, @STransDate  DateType
, @SReasonCode ReasonCodeType
, @SConsign    ListYesNoType
, @SWorkkey    LongListType
, @CallArg     LongListType = NULL
, @PackNum     PackNumType = NULL
, @Infobar     InfobarType OUTPUT
, @BatchId     BatchIdType = NULL
, @SOrigInvoice InvNumType = NULL
, @SReasonText FormEditorType = NULL
, @ImportDocId ImportDocIdType
, @ExportDocId ExportDocIdType
, @SkipCreditCheck ListYesNoType = 0
, @CredHold   ListYesNoType = 0 OUTPUT
, @EmpNum      EmpNumType = NULL
, @ContainerNum ContainerNumType = NULL
, @ShipmentId   ShipmentIdType = NULL
) AS

   -- Check for existence of Generic External Touch Point routine (this section was generated by SpETPCodeSp and inserted by CallETPs.exe):
   --IF OBJECT_ID(N'dbo.EXTGEN_COShippingTrxPostSp') IS NOT NULL
   --BEGIN
   --   DECLARE @EXTGEN_SpName sysname
   --   SET @EXTGEN_SpName = N'dbo.EXTGEN_COShippingTrxPostSp'
   --   -- Invoke the ETP routine, passing in (and out) this routine's parameters:
   --   DECLARE @EXTGEN_Severity int
   --   EXEC @EXTGEN_Severity = @EXTGEN_SpName
   --      @SCoNum
   --      , @SCoLine
   --      , @SCoRel
   --      , @SDoNum
   --      , @SDoLine
   --      , @SLoc
   --      , @SLot
   --      , @OKtoCreateLotLoc
   --      , @SItem
   --      , @SQty
   --      , @SReturn
   --      , @SRetToStock
   --      , @STransDate
   --      , @SReasonCode
   --      , @SConsign
   --      , @SWorkkey
   --      , @CallArg
   --      , @PackNum
   --      , @Infobar OUTPUT
   --      , @BatchId
   --      , @SOrigInvoice
   --      , @SReasonText
   --      , @ImportDocId
   --      , @ExportDocId
   --      , @SkipCreditCheck
   --      , @CredHold OUTPUT
   --      , @EmpNum
   --      , @ContainerNum
   --      , @ShipmentId

   --   -- ETP routine can RETURN 1 to signal that the remainder of this standard routine should now proceed:
   --   IF @EXTGEN_Severity <> 1
   --      RETURN @EXTGEN_Severity
   --END
   ---- End of Generic External Touch Point code.

IF @ContainerNum IS NOT NULL
BEGIN
   UPDATE container
   SET ref_num = NULL
   WHERE container_num = @ContainerNum

   EXEC dbo.ContainerDeleteSp
        @PContainerNum = @ContainerNum
      , @Infobar       = @Infobar OUTPUT
END

IF @SDoLine IS NULL
   SET @SDoLine = 0

if @SReturn IS NULL
   SET @SReturn = 0

DECLARE
   @MsgSeverity int
, @MsgParm2 nvarchar(132)
, @SessionID RowPointerType
declare
 @__BufferError InfobarType
, @CustomerPrintPackInv ListYesNoType
,@DoHdrRowPointer RowPointerType
,@DoHdrCustNum CustNumType
,@DoHdrDoNum DoNumType
,@DoHdrCustSeq CustSeqType
,@DoHdrStat DoStatusType
,@DoHdrDoValue AmtTotType
,@EndtypeRowPointer RowPointerType
,@EndtypeCgsMatlAcct AcctType
,@EndtypeCgsMatlAcctUnit1 UnitCode1Type
,@EndtypeCgsMatlAcctUnit2 UnitCode2Type
,@EndtypeCgsMatlAcctUnit3 UnitCode3Type
,@EndtypeCgsMatlAcctUnit4 UnitCode4Type
,@EndtypeCgsLbrAcct AcctType
,@EndtypeCgsLbrAcctUnit1 UnitCode1Type
,@EndtypeCgsLbrAcctUnit2 UnitCode2Type
,@EndtypeCgsLbrAcctUnit3 UnitCode3Type
,@EndtypeCgsLbrAcctUnit4 UnitCode4Type
,@EndtypeCgsFovhdAcct AcctType
,@EndtypeCgsFovhdAcctUnit1 UnitCode1Type
,@EndtypeCgsFovhdAcctUnit2 UnitCode2Type
,@EndtypeCgsFovhdAcctUnit3 UnitCode3Type
,@EndtypeCgsFovhdAcctUnit4 UnitCode4Type
,@EndtypeCgsVovhdAcct AcctType
,@EndtypeCgsVovhdAcctUnit1 UnitCode1Type
,@EndtypeCgsVovhdAcctUnit2 UnitCode2Type
,@EndtypeCgsVovhdAcctUnit3 UnitCode3Type
,@EndtypeCgsVovhdAcctUnit4 UnitCode4Type
,@EndtypeCgsOutAcct AcctType
,@EndtypeCgsOutAcctUnit1 UnitCode1Type
,@EndtypeCgsOutAcctUnit2 UnitCode2Type
,@EndtypeCgsOutAcctUnit3 UnitCode3Type
,@EndtypeCgsOutAcctUnit4 UnitCode4Type
,@DoLineRowPointer RowPointerType
,@DoLineDoLine DoLineType
,@DoLineDoNum DoNumType
,@TmpSerSerNum SerNumType
,@TmpSerRowPointer RowPointerType
,@ItempriceCurrCode CurrCodeType
,@ItempriceUnitPrice1 CostPrcType
,@ItempriceRowPointer RowPointerType
,@ItemRowPointer RowPointerType
,@ItemProductCode ProductCodeType
,@ItemSerialTracked ListYesNoType
,@ItemItem ItemType
,@ItemCostMethod CostMethodType
,@ItemUnitWeight ItemWeightType
,@ItemLotTracked ListYesNoType
,@ItemLbrCost CostPrcType
,@ItemMatlCost CostPrcType
,@ItemFovhdCost CostPrcType
,@ItemVovhdCost CostPrcType
,@ItemOutCost CostPrcType
,@ItemCostType CostTypeType
,@ItemUnitCost CostPrcType
,@ItemShelfLife ShelfLifeType
, @ItemUWsPrice AmountType
,@MatltranAmt1RowPointer RowPointerType
,@MatltranAmt1TransNum MatlTransNumType
,@MatltranAmt1TransSeq DateSeqType
,@MatltranAmt1LbrAmt AmountType
,@MatltranAmt1MatlAmt AmountType
,@MatltranAmt1FovhdAmt AmountType
,@MatltranAmt1VovhdAmt AmountType
,@MatltranAmt1OutAmt AmountType
,@MatltranAmt1Amt AmountType
,@MatltranAmt1Acct AcctType
,@MatltranAmt1LbrAcct AcctType
,@MatltranAmt1LbrAcctUnit1 UnitCode1Type
,@MatltranAmt1LbrAcctUnit2 UnitCode2Type
,@MatltranAmt1LbrAcctUnit3 UnitCode3Type
,@MatltranAmt1LbrAcctUnit4 UnitCode4Type
,@MatltranAmt1MatlAcct AcctType
,@MatltranAmt1MatlAcctUnit1 UnitCode1Type
,@MatltranAmt1MatlAcctUnit2 UnitCode2Type
,@MatltranAmt1MatlAcctUnit3 UnitCode3Type
,@MatltranAmt1MatlAcctUnit4 UnitCode4Type
,@MatltranAmt1FovhdAcct AcctType
,@MatltranAmt1FovhdAcctUnit1 UnitCode1Type
,@MatltranAmt1FovhdAcctUnit2 UnitCode2Type
,@MatltranAmt1FovhdAcctUnit3 UnitCode3Type
,@MatltranAmt1FovhdAcctUnit4 UnitCode4Type
,@MatltranAmt1VovhdAcct AcctType
,@MatltranAmt1VovhdAcctUnit1 UnitCode1Type
,@MatltranAmt1VovhdAcctUnit2 UnitCode2Type
,@MatltranAmt1VovhdAcctUnit3 UnitCode3Type
,@MatltranAmt1VovhdAcctUnit4 UnitCode4Type
,@MatltranAmt1OutAcct AcctType
,@MatltranAmt1OutAcctUnit1 UnitCode1Type
,@MatltranAmt1OutAcctUnit2 UnitCode2Type
,@MatltranAmt1OutAcctUnit3 UnitCode3Type
,@MatltranAmt1OutAcctUnit4 UnitCode4Type
,@XCoShipRowPointer RowPointerType
,@XCoShipDateSeq DateSeqType
,@XCoShipShipDate DateType
,@MatltranAmt2RowPointer RowPointerType
,@MatltranAmt2TransNum MatlTransNumType
,@MatltranAmt2TransSeq DateSeqType
,@MatltranAmt2LbrAmt AmountType
,@MatltranAmt2MatlAmt AmountType
,@MatltranAmt2FovhdAmt AmountType
,@MatltranAmt2VovhdAmt AmountType
,@MatltranAmt2OutAmt AmountType
,@MatltranAmt2Amt AmountType
,@MatltranAmt2Acct AcctType
,@MatltranAmt2MatlAcct AcctType
,@MatltranAmt2MatlAcctUnit1 UnitCode1Type
,@MatltranAmt2MatlAcctUnit2 UnitCode2Type
,@MatltranAmt2MatlAcctUnit3 UnitCode3Type
,@MatltranAmt2MatlAcctUnit4 UnitCode4Type
,@MatltranAmt2LbrAcct AcctType
,@MatltranAmt2LbrAcctUnit1 UnitCode1Type
,@MatltranAmt2LbrAcctUnit2 UnitCode2Type
,@MatltranAmt2LbrAcctUnit3 UnitCode3Type
,@MatltranAmt2LbrAcctUnit4 UnitCode4Type
,@MatltranAmt2FovhdAcct AcctType
,@MatltranAmt2FovhdAcctUnit1 UnitCode1Type
,@MatltranAmt2FovhdAcctUnit2 UnitCode2Type
,@MatltranAmt2FovhdAcctUnit3 UnitCode3Type
,@MatltranAmt2FovhdAcctUnit4 UnitCode4Type
,@MatltranAmt2VovhdAcct AcctType
,@MatltranAmt2VovhdAcctUnit1 UnitCode1Type
,@MatltranAmt2VovhdAcctUnit2 UnitCode2Type
,@MatltranAmt2VovhdAcctUnit3 UnitCode3Type
,@MatltranAmt2VovhdAcctUnit4 UnitCode4Type
,@MatltranAmt2OutAcct AcctType
,@MatltranAmt2OutAcctUnit1 UnitCode1Type
,@MatltranAmt2OutAcctUnit2 UnitCode2Type
,@MatltranAmt2OutAcctUnit3 UnitCode3Type
,@MatltranAmt2OutAcctUnit4 UnitCode4Type
,@ProdcodeRowPointer RowPointerType
,@ProdcodeMarkup MarkupType
,@ProdcodeUnit UnitCode2Type
,@ProdcodeInvAdjAcct AcctType
,@ProdcodeInvAdjAcctUnit1 UnitCode1Type
,@ProdcodeInvAdjAcctUnit2 UnitCode2Type
,@ProdcodeInvAdjAcctUnit3 UnitCode3Type
,@ProdcodeInvAdjAcctUnit4 UnitCode4Type
,@ProdcodeProductCode ProductCodeType
,@TaxparmsTwoExchRates ListYesNoType
,@InvparmsNegFlag ListYesNoType
,@InvparmsRetentionDays RetentionDaysType
,@PlacesQtyUnit DecimalPlacesType
,@XItempriceRowPointer RowPointerType
,@XItempriceEffectDate Date4Type
,@MatltranRowPointer RowPointerType
,@MatltranLbrCost CostPrcType
,@MatltranMatlCost CostPrcType
,@MatltranFovhdCost CostPrcType
,@MatltranVovhdCost CostPrcType
,@MatltranOutCost CostPrcType
,@MatltranCost CostPrcType
,@MatltranRefType RefTypeIJKOPRSTWType
,@MatltranRefNum EmpJobCoPoRmaProjPsTrnNumType
,@MatltranRefLineSuf CoLineSuffixPoLineProjTaskRmaTrnLineType
,@MatltranRefRelease CoReleaseOperNumPoReleaseType
,@MatltranTransType MatlTransTypeType
,@MatltranQty QtyUnitType
,@MatltranTransDate DateType
,@MatltranItem ItemType
,@MatltranWhse WhseType
,@MatltranLoc LocType
,@MatltranLot LotType
,@MatltranUserCode UserCodeType
,@MatltranReasonCode ReasonCodeType
,@MatltranTransNum MatlTransNumType
,@MatltranShipDateSeq DateSeqType
,@CommodityRowPointer RowPointerType
,@CommoditySupplQtyReq ListYesNoType
,@CommodityCommCode CommodityCodeType
,@LotLocRowPointer RowPointerType
,@LotLocLbrCost CostPrcType
,@LotLocMatlCost CostPrcType
,@LotLocFovhdCost CostPrcType
,@LotLocVovhdCost CostPrcType
,@LotLocOutCost CostPrcType
,@LotLocWhse WhseType
,@LotLocItem ItemType
,@LotLocLoc LocType
,@LotLocLot LotType
,@LotLocQtyOnHand QtyUnitType
,@LotLocUnitCost CostPrcType
,@ItemwhseQtyOnHand QtyTotlType
,@ItemwhseQtyRsvdCo QtyTotlType
,@ItemwhseQtyAllocCo QtyTotlType
,@ItemwhseCycleType CycleTypeType
,@ItemwhseCycleFlag ListYesNoType
,@ItemwhseQtySoldYtd QtyCumuType
,@ItemwhseQtyMrb QtyTotlType
,@ItemwhseRowPointer RowPointerType
,@RsvdInvRowPointer RowPointerType
,@RsvdInvQtyRsvd QtyUnitNoNegType
,@MatltranAmt3RowPointer RowPointerType
,@MatltranAmt3TransNum MatlTransNumType
,@MatltranAmt3TransSeq DateSeqType
,@MatltranAmt3Acct AcctType
,@MatltranAmt3AcctUnit1 UnitCode1Type
,@MatltranAmt3AcctUnit2 UnitCode2Type
,@MatltranAmt3AcctUnit3 UnitCode3Type
,@MatltranAmt3AcctUnit4 UnitCode4Type
,@MatltranAmt3Amt AmountType
,@ParmsSite SiteType
,@ParmsEcReporting ListYesNoType
,@ParmsPostJour ListYesNoType
,@CustaddrCurrCode CurrCodeType
,@CustaddrCustNum CustNumType
,@CustLcrRowPointer RowPointerType
,@CustLcrCurrCode CurrCodeType
,@CustLcrShipValue AmountType
,@SerialRowPointer RowPointerType
,@SerialStat SerialStatusType
,@SerialSerNum SerNumType
,@SerialInvNum InvNumType
,@SerialLoc LocType
,@SerialLot LotType
,@SerialWhse WhseType
,@SerialRefType RefTypeOType
,@SerialRefNum CoNumType
,@SerialRefLine CoLineType
,@SerialRefRelease CoReleaseType
,@SerialDoNum DoNumType
,@SerialDoLine DoLineType
,@SerialDoSeq DoSeqType
,@SerialItem ItemType
,@SerialShipDate DateType
,@SerialDateSeq DateSeqType
,@SerialCreateDate DateType
,@SerialPurgeDate DateType
,@SerialExpDate DateType
,@SerialShipmentId ShipmentIdType
,@SsdRowPointer RowPointerType
,@SsdTransDate DateType
,@SsdTransIndicator TransIndicatorType
,@SsdRefType SsdRefTypeType
,@SsdTransQty QtyUnitType
,@SsdUnitWeight UnitWeightType
,@SsdCurrCode CurrCodeType
,@SsdForeignValue AmountType
,@SsdExchRate ExchRateType
,@SsdExportValue AmountType
,@SsdCommCode CommodityCodeType
,@SsdTransNat TransNatType
,@SsdTransNat2 TransNat2Type
,@SsdProcessInd ProcessIndType
,@SsdDelterm DeltermType
,@SsdOrigin EcCodeType
,@SsdEcCode EcCodeType
,@SsdTransport TransportType
,@SsdPrinted ListYesNoType
,@SsdTaxDistrict TaxDistrictType
,@SsdPortOfEntry PortOfEntryType
,@SsdStatValue AmountType
,@SsdVendNum VendNumType
,@SsdRefNum CoCustPoProjRmaTrnVendNumType
,@SsdRefLineSuf CoLineProjTaskPoRmaTrnLineInvNumVoucherType
,@SsdRefRelease CoPoReleaseArInvSeqType
,@SsdDateSeq DateSeqType
,@SsdSupplQty QtyPerType
,@XCurrencyRowPointer RowPointerType
,@XCurrencyPlaces DecimalPlacesType
,@XCurrencyPlacesCp DecimalPlacesType
,@CoitemRowPointer RowPointerType
,@CoitemStat CoitemStatusType
,@CoitemWhse WhseType
,@CoitemPrice CostPrcType
,@CoitemDisc LineDiscType
,@CoitemEcCode EcCodeType
,@CoitemExportValue AmountType
,@CoitemTransNat TransNatType
,@CoitemTransNat2 TransNat2Type
,@CoitemCommCode CommodityCodeType
,@CoitemSupplQtyConvFactor UMConvFactorType
,@CoitemUnitWeight UnitWeightType
,@CoitemProcessInd ProcessIndType
,@CoitemDelterm DeltermType
,@CoitemOrigin EcCodeType
,@CoitemTransport TransportType
,@CoitemCoNum CoNumType
,@CoitemCoLine CoLineType
,@CoitemCoRelease CoReleaseType
,@CoitemConsNum ConsignmentsType
,@CoitemItem ItemType
,@CoitemQtyShipped QtyUnitNoNegType
,@OrigCoitemQtyShipped QtyUnitNoNegType
,@CoitemCgsTotalLbr AmountType
,@CoitemCgsTotalMatl AmountType
,@CoitemCgsTotalFovhd AmountType
,@CoitemCgsTotalVovhd AmountType
,@CoitemCgsTotalOut AmountType
,@CoitemCgsTotal AmountType
,@CoitemQtyOrdered QtyUnitNoNegType
,@CoitemQtyInvoiced QtyUnitNoNegType
,@CoitemQtyReturned QtyUnitNoNegType
,@CoitemPrgBillTot AmountType
,@CoitemPrgBillApp AmountType
,@CoitemQtyPacked QtyUnitNoNegType
,@CoitemQtyPicked QtyUnitNoNegType
,@CoitemQtyReady QtyUnitNoNegType
,@CoitemQtyRsvd QtyUnitType
,@CoitemShipDate DateType
,@CoitemLbrCost CostPrcType
,@CoitemMatlCost CostPrcType
,@CoitemFovhdCost CostPrcType
,@CoitemVovhdCost CostPrcType
,@CoitemOutCost CostPrcType
,@CoitemCost CostPrcType
,@CoitemUM UMType
,@CoitemShipSite SiteType
,@CoitemRefType RefTypeIJKPRTType
,@CoitemRefNum JobPoProjReqTrnNumType
,@CoItemTaxCode1 TaxCodeType
,@CoItemTaxCode2 TaxCodeType
,@DoSeqRowPointer RowPointerType
,@DoSeqDoSeq DoSeqType
,@DoSeqDoNum DoNumType
,@DoSeqDoLine DoLineType
,@DoSeqRefNum CoNumType
,@DoSeqRefLine CoLineType
,@DoSeqRefRelease CoReleaseType
,@DoSeqShipDate DateType
,@DoSeqDateSeq DateSeqType
,@ReasonRowPointer RowPointerType
,@ReasonTransIndicator TransIndicatorType
,@ReasonTransNat TransNatType
,@ReasonTransNat2 TransNat2Type
,@ReasonReasonCode ReasonCodeType
,@CurrencyPlaces DecimalPlacesType
,@CurrencyPlacesCp DecimalPlacesType
,@CurrparmsCurrCode CurrCodeType
,@DistacctRowPointer RowPointerType
,@DistacctCgsAcct AcctType
,@DistacctCgsAcctUnit1 UnitCode1Type
,@DistacctCgsAcctUnit2 UnitCode2Type
,@DistacctCgsAcctUnit3 UnitCode3Type
,@DistacctCgsAcctUnit4 UnitCode4Type
,@DistacctCgsLbrAcct AcctType
,@DistacctCgsLbrAcctUnit1 UnitCode1Type
,@DistacctCgsLbrAcctUnit2 UnitCode2Type
,@DistacctCgsLbrAcctUnit3 UnitCode3Type
,@DistacctCgsLbrAcctUnit4 UnitCode4Type
,@DistacctCgsFovhdAcct AcctType
,@DistacctCgsFovhdAcctUnit1 UnitCode1Type
,@DistacctCgsFovhdAcctUnit2 UnitCode2Type
,@DistacctCgsFovhdAcctUnit3 UnitCode3Type
,@DistacctCgsFovhdAcctUnit4 UnitCode4Type
,@DistacctCgsVovhdAcct AcctType
,@DistacctCgsVovhdAcctUnit1 UnitCode1Type
,@DistacctCgsVovhdAcctUnit2 UnitCode2Type
,@DistacctCgsVovhdAcctUnit3 UnitCode3Type
,@DistacctCgsVovhdAcctUnit4 UnitCode4Type
,@DistacctCgsOutAcct AcctType
,@DistacctCgsOutAcctUnit1 UnitCode1Type
,@DistacctCgsOutAcctUnit2 UnitCode2Type
,@DistacctCgsOutAcctUnit3 UnitCode3Type
,@DistacctCgsOutAcctUnit4 UnitCode4Type
,@DistacctInvMatlAcct AcctType
,@DistacctInvMatlAcctUnit1 UnitCode1Type
,@DistacctInvMatlAcctUnit2 UnitCode2Type
,@DistacctInvMatlAcctUnit3 UnitCode3Type
,@DistacctInvMatlAcctUnit4 UnitCode4Type
,@CoShipRowPointer RowPointerType
,@CoShipDateSeq DateSeqType
,@CoShipDoNum DoNumType
,@CoShipDoLine DoLineType
,@CoShipDoSeq DoSeqType
,@CoShipQtyInvoiced QtyUnitType
,@CoShipQtyReturned QtyUnitType
,@CoShipLbrCost CostPrcType
,@CoShipMatlCost CostPrcType
,@CoShipFovhdCost CostPrcType
,@CoShipVovhdCost CostPrcType
,@CoShipOutCost CostPrcType
,@CoShipCost CostPrcType
,@CoShipCoNum CoNumType
,@CoShipCoLine CoLineType
,@CoShipCoRelease CoReleaseType
,@CoShipShipDate DateType
,@CoShipQtyApproved QtyUnitType
,@CoShipQtyShipped QtyUnitType
,@CoShipQtyShippedConv QtyUnitType
,@CoShipPrice CostPrcType
,@CoShipPriceConv CostPrcType
,@CoShipUnitWeight UnitWeightType
,@CoShipByCons ListYesNoType
,@CoShipShipmentId ShipmentIdType
,@ItemlocRowPointer RowPointerType
,@ItemlocWhse WhseType
,@ItemlocItem ItemType
,@ItemlocLoc LocType
,@ItemlocMrbFlag ListYesNoType
,@ItemlocLocType LocTypeType
,@ItemlocQtyOnHand QtyUnitType
,@ItemlocInvAcct AcctType
,@ItemlocLbrAcct AcctType
,@ItemlocFovhdAcct AcctType
,@ItemlocVovhdAcct AcctType
,@ItemlocOutAcct AcctType
,@ItemlocInvAcctUnit1 UnitCode1Type
,@ItemlocInvAcctUnit2 UnitCode2Type
,@ItemlocInvAcctUnit3 UnitCode3Type
,@ItemlocInvAcctUnit4 UnitCode4Type
,@ItemlocLbrAcctUnit1 UnitCode1Type
,@ItemlocLbrAcctUnit2 UnitCode2Type
,@ItemlocLbrAcctUnit3 UnitCode3Type
,@ItemlocLbrAcctUnit4 UnitCode4Type
,@ItemlocFovhdAcctUnit1 UnitCode1Type
,@ItemlocFovhdAcctUnit2 UnitCode2Type
,@ItemlocFovhdAcctUnit3 UnitCode3Type
,@ItemlocFovhdAcctUnit4 UnitCode4Type
,@ItemlocVovhdAcctUnit1 UnitCode1Type
,@ItemlocVovhdAcctUnit2 UnitCode2Type
,@ItemlocVovhdAcctUnit3 UnitCode3Type
,@ItemlocVovhdAcctUnit4 UnitCode4Type
,@ItemlocOutAcctUnit1 UnitCode1Type
,@ItemlocOutAcctUnit2 UnitCode2Type
,@ItemlocOutAcctUnit3 UnitCode3Type
,@ItemlocOutAcctUnit4 UnitCode4Type
,@ItemlocLbrCost CostPrcType
,@ItemlocMatlCost CostPrcType
,@ItemlocFovhdCost CostPrcType
,@ItemlocVovhdCost CostPrcType
,@ItemlocOutCost CostPrcType
,@ItemlocUnitCost CostPrcType
,@ItemlocPermFlag ListYesNoType
,@ItemlifoItemlocInvAcct AcctType
,@ItemlifoItemlocLbrAcct AcctType
,@ItemlifoItemlocFovhdAcct AcctType
,@ItemlifoItemlocVovhdAcct AcctType
,@ItemlifoItemlocOutAcct AcctType
,@ItemlifoItemlocInvAcctUnit1 UnitCode1Type
,@ItemlifoItemlocInvAcctUnit2 UnitCode2Type
,@ItemlifoItemlocInvAcctUnit3 UnitCode3Type
,@ItemlifoItemlocInvAcctUnit4 UnitCode4Type
,@ItemlifoItemlocLbrAcctUnit1 UnitCode1Type
,@ItemlifoItemlocLbrAcctUnit2 UnitCode2Type
,@ItemlifoItemlocLbrAcctUnit3 UnitCode3Type
,@ItemlifoItemlocLbrAcctUnit4 UnitCode4Type
,@ItemlifoItemlocFovhdAcctUnit1 UnitCode1Type
,@ItemlifoItemlocFovhdAcctUnit2 UnitCode2Type
,@ItemlifoItemlocFovhdAcctUnit3 UnitCode3Type
,@ItemlifoItemlocFovhdAcctUnit4 UnitCode4Type
,@ItemlifoItemlocVovhdAcctUnit1 UnitCode1Type
,@ItemlifoItemlocVovhdAcctUnit2 UnitCode2Type
,@ItemlifoItemlocVovhdAcctUnit3 UnitCode3Type
,@ItemlifoItemlocVovhdAcctUnit4 UnitCode4Type
,@ItemlifoItemlocOutAcctUnit1 UnitCode1Type
,@ItemlifoItemlocOutAcctUnit2 UnitCode2Type
,@ItemlifoItemlocOutAcctUnit3 UnitCode3Type
,@ItemlifoItemlocOutAcctUnit4 UnitCode4Type
,@ItemlifoRowPointer RowPointerType
,@ItemlifoItem ItemType
,@ItemlifoInvAcct AcctType
,@ItemlifoInvAcctUnit1 UnitCode1Type
,@ItemlifoInvAcctUnit2 UnitCode2Type
,@ItemlifoInvAcctUnit3 UnitCode3Type
,@ItemlifoInvAcctUnit4 UnitCode4Type
,@ItemlifoLbrAcct AcctType
,@ItemlifoLbrAcctUnit1 UnitCode1Type
,@ItemlifoLbrAcctUnit2 UnitCode2Type
,@ItemlifoLbrAcctUnit3 UnitCode3Type
,@ItemlifoLbrAcctUnit4 UnitCode4Type
,@ItemlifoFovhdAcct AcctType
,@ItemlifoFovhdAcctUnit1 UnitCode1Type
,@ItemlifoFovhdAcctUnit2 UnitCode2Type
,@ItemlifoFovhdAcctUnit3 UnitCode3Type
,@ItemlifoFovhdAcctUnit4 UnitCode4Type
,@ItemlifoVovhdAcct AcctType
,@ItemlifoVovhdAcctUnit1 UnitCode1Type
,@ItemlifoVovhdAcctUnit2 UnitCode2Type
,@ItemlifoVovhdAcctUnit3 UnitCode3Type
,@ItemlifoVovhdAcctUnit4 UnitCode4Type
,@ItemlifoOutAcct AcctType
,@ItemlifoOutAcctUnit1 UnitCode1Type
,@ItemlifoOutAcctUnit2 UnitCode2Type
,@ItemlifoOutAcctUnit3 UnitCode3Type
,@ItemlifoOutAcctUnit4 UnitCode4Type
,@ItemlifoTransDate DateTimeType
,@ItemlifoQty QtyUnitType
,@ItemlifoLbrCost CostPrcType
,@ItemlifoMatlCost CostPrcType
,@ItemlifoFovhdCost CostPrcType
,@ItemlifoVovhdCost CostPrcType
,@ItemlifoOutCost CostPrcType
,@ItemlifoUnitCost CostPrcType
,@CoRowPointer RowPointerType
,@CoCreditHold ListYesNoType
,@CoCoNum CoNumType
,@CoCustNum CustNumType
,@CoEndUserType EndUserTypeType
,@CoCustSeq CustSeqType
,@CoType CoTypeType
,@CoDisc       OrderDiscType
,@CoLcrNum     LcrNumType
,@CoExchRate   ExchRateType
,@CoFixedRate  ListYesNoType
,@CoOrigSite   SiteType
,@CoOrderDate  DateType
,@CoExportType ListDirectIndirectNonExportType
, @CoTermsCode TermsCodeType
, @CoUseExchRate ListYesNoType
, @CoTaxCode1 TaxCodeType
, @CoTaxCode2 TaxCodeType
, @CoShipCode ShipCodeType
,@CoShipmentApprovalRequired ListYesNoType
,@CoParmsUseAltPriceCalc ListYesNoType

,@CoShipOrigInvoice InvNumType
,@CoShipReasonText FormEditorType
,@ItemlifoNewFlag ListYesNoType

,@ShipmentLine    ShipmentLineType
,@ShipmentSeq     ShipmentSequenceType
,@ShipmentValue   AmtTotType

,@ItemInvAcctMsg  MessageType

DECLARE
-- temporary variable of fetch table co_ship_approval_log
  @TCoShipApprLogRowPointer    RowPointerType
, @TCoShipApprLogQtyAppr       QtyUnitType
, @TCoShipApprLogApproveDate   DateType
, @TCoShipApprLogCOLine        CoLineType
, @TCoShipApprLogCONum         CoNumType
, @TCoShipApprLogCORelease     CoReleaseType
, @TCoShipApprLogShipDate      DateType
, @TCoShipApprLogDateSeq       DateSeqType
, @TCoShipApprLogSeq           CoShipApprovalLogSequenceType
, @TCoShipApprLogInvNum        InvNumType
--, @TCoShipApprLogInvSeq        InvSeqType
, @TCoShipApprLogControlPrefix JourControlPrefixType
, @TCoShipApprLogControlSite   SiteType
, @TCoShipApprLogControlYear   FiscalYearType
, @TCoShipApprLogControlPeriod FinPeriodType
, @TCoShipApprLogControlNumber LastTranType

DECLARE
  @Severity           INT
, @TTransNum          MatlTransNumType
, @TId                LongListType
, @EndTrans           JournalSeqType
, @TAdjQty            QtyUnitType
, @TChosenResSerial   QtyUnitNoNegType
, @TDateSeq           DateSeqType
, @TTotPostLbr        AmountType
, @TTotPostMatl       AmountType
, @TTotPostFovhd      AmountType
, @TTotPostVovhd      AmountType
, @TTotPostOut        AmountType
, @TNewCostLbr        CostPrcType
, @TNewCostMatl       CostPrcType
, @TNewCostFovhd      CostPrcType
, @TNewCostVovhd      CostPrcType
, @TNewCostOut        CostPrcType
, @TOldCostLbr        CostPrcType
, @TOldCostMatl       CostPrcType
, @TOldCostFovhd      CostPrcType
, @TOldCostVovhd      CostPrcType
, @TOldCostOut        CostPrcType
, @TAdjPostLbr        AmountType
, @TAdjPostMatl       AmountType
, @TAdjPostFovhd      AmountType
, @TAdjPostVovhd      AmountType
, @TAdjPostOut        AmountType
, @SQtyRem            QtyUnitType
, @SQtyMove           QtyUnitType
, @SQtyAdj            QtyUnitType
, @TCgsAcct           AcctType
, @TCgsAcctUnit1      UnitCode1Type
, @TCgsAcctUnit2      UnitCode2Type
, @TCgsAcctUnit3      UnitCode3Type
, @TCgsAcctUnit4      UnitCode4Type
, @TCgsLbrAcct        AcctType
, @TCgsLbrAcctUnit1   UnitCode1Type
, @TCgsLbrAcctUnit2   UnitCode2Type
, @TCgsLbrAcctUnit3   UnitCode3Type
, @TCgsLbrAcctUnit4   UnitCode4Type
, @TCgsFovhdAcct      AcctType
, @TCgsFovhdAcctUnit1 UnitCode1Type
, @TCgsFovhdAcctUnit2 UnitCode2Type
, @TCgsFovhdAcctUnit3 UnitCode3Type
, @TCgsFovhdAcctUnit4 UnitCode4Type
, @TCgsVovhdAcct      AcctType
, @TCgsVovhdAcctUnit1 UnitCode1Type
, @TCgsVovhdAcctUnit2 UnitCode2Type
, @TCgsVovhdAcctUnit3 UnitCode3Type
, @TCgsVovhdAcctUnit4 UnitCode4Type
, @TCgsOutAcct        AcctType
, @TCgsOutAcctUnit1   UnitCode1Type
, @TCgsOutAcctUnit2   UnitCode2Type
, @TCgsOutAcctUnit3   UnitCode3Type
, @TCgsOutAcctUnit4   UnitCode4Type
, @TRef               ReferenceType
, @TQtyCheck          GenericNoType
, @TCredhold          LongListType
, @DiscPrice          GenericDecimalType
, @TShipPrice         AmountType
, @TDomPlaces         DecimalPlacesType
, @TCost              CostPrcType
, @UomConvFactor      UMConvFactorType
, @TPlaces            DecimalPlacesType
, @TOrderBal          AmountType
, @TLcrShipPrice      AmountType
, @TForValue          AmountType
, @TRate              ExchRateType
, @TCase              LongListType
, @TExportValue       AmountType
, @TTransInd          TransIndicatorType
, @TTransNat          TransNatType
, @TTransNat2         TransNat2Type
, @TSQty              QtyUnitType
, @CoitemCustItem     ItemType
, @NextTick DateType
, @TimeIncrement int
, @Tacct_label        NVARCHAR(255)
, @TempSalesTax AmountType
, @TempSalesTax2 AmountType

, @OrigMatlRowPointer RowPointerType
, @OrigMatlCost       CostPrcType
, @OrigMatlMatlCost   CostPrcType
, @OrigMatlLbrCost    CostPrcType
, @OrigMatlFovhdCost  CostPrcType
, @OrigMatlVovhdCost  CostPrcType
, @OrigMatlOutCost    CostPrcType
, @UseOriginalLotCost ListYesNoType

, @AvgMatlCost CostPrcType
, @AvgLbrCost CostPrcType
, @AvgFovhdCost CostPrcType
, @AvgVovhdCost CostPrcType
, @AvgOutCost CostPrcType

declare
  @ControlPrefix JourControlPrefixType
, @ControlSite SiteType
, @ControlYear FiscalYearType
, @ControlPeriod FinPeriodType
, @ControlNumber LastTranType
, @ItemTaxFreeMatl ListYesNoType

, @SQtyConv QtyPerType
, @UM UMType
, @QTYINT INT
, @PreAssignCount INT

, @WhseEcCode EcCodeType
, @CustomerEcCode EcCodeType

Declare @ParmsEcConvFactor EcConvFactorType
Declare @ObjectName sysname

DECLARE @CostItemAtWhse ListYesNoType
DECLARE @NonInventoryItem FlagNyType

DECLARE
 @CoDemandingSite                   SiteType
, @CoDemandingSitePoNum             PoNumType
, @PoAllAutoReceiveDemandingSitePo  ListYesNoType

SET @Severity         = 0
SET @TTransNum        = 0
SET @EndTrans         = 0
SET @TAdjQty          = 0
SET @TChosenResSerial = 0
SET @TDateSeq         = 0
SET @TTotPostLbr      = 0
SET @TTotPostMatl     = 0
SET @TTotPostFovhd    = 0
SET @TTotPostVovhd    = 0
SET @TTotPostOut      = 0
SET @TNewCostLbr      = 0
SET @TNewCostMatl     = 0
SET @TNewCostFovhd    = 0
SET @TNewCostVovhd    = 0
SET @TNewCostOut      = 0
SET @TOldCostLbr      = 0
SET @TOldCostMatl     = 0
SET @TOldCostFovhd    = 0
SET @TOldCostVovhd    = 0
SET @TOldCostOut      = 0
SET @TAdjPostLbr      = 0
SET @TAdjPostMatl     = 0
SET @TAdjPostFovhd    = 0
SET @TAdjPostVovhd    = 0
SET @TAdjPostOut      = 0
SET @SQtyRem          = 0
SET @SQtyMove         = 0
SET @SQtyAdj          = 0
SET @TQtyCheck        = 0
SET @TCost            = 0
SET @UomConvFactor    = 0
SET @TPlaces          = 0
SET @TLcrShipPrice    = 0
SET @TForValue        = 0
SET @TExportValue     = 0
SET @CredHold         = 0
SET @ItemInvAcctMsg   = NULL

SET @TId = 'CO Dist'
SET @ObjectName = object_name(@@procid)
SET @SessionID = dbo.SessionIDSp()
SET @NonInventoryItem = 0

-- NOT ((@SReturn <> 0 and @SQty > 0) or (@SReturn = 0 and @SQty < 0)) = @SQty <= 0 AND @SReturn <> 0 OR @SReturn = 0 AND @SQty >= 0

-- NOT ((@SReturn <> 0 and @SQty > 0) or (@SReturn = 0 and @SQty <= 0)) = @SQty <= 0 AND @SReturn <> 0 OR @SReturn = 0 AND @SQty > 0

-- NOT ((@SReturn <> 0 and @SQty >= 0) or (@SReturn = 0 and @SQty <= 0)) = @SQty < 0 AND @SReturn <> 0 OR @SReturn = 0 AND @SQty > 0

SELECT @CostItemAtWhse = cost_item_at_whse FROM invparms WITH (READUNCOMMITTED)

select
 @ParmsSite = parms.site
,@ParmsEcReporting = parms.ec_reporting
,@ParmsPostJour = parms.post_jour
,@ParmsEcConvFactor = parms.ec_conv_fact
from parms with (readuncommitted)
if @@rowcount <> 1
begin
   exec @Severity = dbo.MsgAppSp @__BufferError OUTPUT, 'E=UniqueRecordNotFound'
      , '@parms'
      , @ObjectName
   exec dbo.RaiseErrorSp @__BufferError, 16, 1
end

select
 @CurrparmsCurrCode = currparms.curr_code
from currparms with (readuncommitted)
if @@rowcount <> 1
begin
   exec @Severity = dbo.MsgAppSp @__BufferError OUTPUT, 'E=UniqueRecordNotFound'
      , '@currparms'
      , @ObjectName
   exec dbo.RaiseErrorSp @__BufferError, 16, 1
end

select
 @XCurrencyRowPointer = x_currency.RowPointer
,@XCurrencyPlaces = x_currency.places
, @XCurrencyPlacesCp = x_currency.places_cp
from currency  as x_currency with (readuncommitted)
where x_currency.curr_code = @CurrparmsCurrCode
if @@rowcount <> 1
   set @XCurrencyRowPointer = null

SET @TDomPlaces = (CASE WHEN (@XCurrencyRowPointer is not null) then @XCurrencyPlaces else 2 END)

select
 @InvparmsNegFlag = invparms.neg_flag
,@InvparmsRetentionDays = invparms.retention_days
, @PlacesQtyUnit = places_qty_unit
from invparms with (readuncommitted)
if @@rowcount <> 1
begin

   exec @Severity = dbo.MsgAppSp @__BufferError OUTPUT, 'E=UniqueRecordNotFound'
      , '@invparms'
      , @ObjectName

   exec dbo.RaiseErrorSp @__BufferError, 16, 1
end

DECLARE @UserCode UserCodeType

SELECT @UserCode = user_local.user_code
FROM UserNames with (readuncommitted)
INNER JOIN user_local with (readuncommitted) ON user_local.Userid = UserNames.Userid
WHERE UserNames.UserName = dbo.UserNameSp()

SELECT @CoParmsUseAltPriceCalc = coparms.use_alt_price_calc
FROM coparms WITH (READUNCOMMITTED)

select
 @CoRowPointer = co.RowPointer
,@CoCreditHold = co.credit_hold
,@CoCoNum = co.co_num
,@CoCustNum = co.cust_num
,@CoEndUserType = co.end_user_type
,@CoCustSeq = co.cust_seq
,@CoType = co.type
,@CoDisc = co.disc
,@CoLcrNum = co.lcr_num
,@CoExchRate = co.exch_rate
,@CoFixedRate = co.fixed_rate
,@CoOrigSite = co.orig_site
,@CoOrderDate = co.order_date
,@CoExportType = co.export_type
,@CoDemandingSite = co.demanding_site
,@CoDemandingSitePoNum = co.demanding_site_po_num
,@CoShipmentApprovalRequired = ISNULL(co.shipment_approval_required,0)
, @CoTermsCode = co.terms_code
, @CoUseExchRate = co.use_exch_rate
, @CoTaxCode1 = co.tax_code1
, @CoTaxCode2 = co.tax_code2
, @CoShipCode = co.ship_code
from co WITH (UPDLOCK)
where co.co_num = @SCoNum
   and (CHARINDEX( co.stat, 'OP') <> 0)
if @@rowcount <> 1
   set @CoRowPointer = null

if @CoRowPointer is null
BEGIN
   EXEC @Severity = dbo.MsgAppSp @Infobar OUTPUT, 'E=NoExistIs1'
      , '@co'
      , '@co.stat'
      , '@:CoStatus:O:P'
      , '@co.co_num'
      , @SCoNum

   GOTO EOF
end
/* Check Credit Hold field of both Customer and Customer Order records */
IF @SQty > 0 AND @SReturn = 0 AND @CoCreditHold <> 0
BEGIN
   EXEC @Severity = dbo.MsgAppSp @Infobar OUTPUT, 'I=IsCompare1'
      , '@co.credit_hold'
      , '@:logical:yes'
      , '@co'
      , '@co.co_num'
      , @CoCoNum

   SET @CredHold = @CoCreditHold
   GOTO EOF
END

if @SQty > 0 and @SReturn = 0 and @SkipCreditCheck = 0
BEGIN
   EXEC @Severity = dbo.ChkcredSp @CoCustNum, @TCredhold OUTPUT

   IF @TCredhold IS NOT NULL
   BEGIN
      exec dbo.MsgConcatSp
        @Infobar = @Infobar OUTPUT
      , @NextMessage = @TCredhold

      GOTO EOF
   end
END
/* End of Credit Hold Check logic */

-- keep precise real time for downstream processing and reports
SET @STransDate = ISNULL(@STransDate, GETDATE())
-- however, remove milliseconds, if any, as if the date and time is from a form
SET @STransDate = DATEADD(MILLISECOND, -DATEPART(MILLISECOND, @STransDate), @STransDate)

IF @CoExportType <> 'N'
BEGIN
   EXEC @Severity = dbo.AddTaxFreeExportSp
        @pRefType   = 'O'
       ,@pRefNum   = @SCoNum
       ,@pRefLineSuf   = @SCoLine
       ,@pRefRelease   = @SCoRel
       ,@pShipDate   = @STransDate
       ,@pShipQty   = @SQty
       ,@pExportDocId   = @ExportDocId
       ,@pItem      = @SItem
       ,@pExportType   = @CoExportType
       ,@Infobar   = @Infobar   OUTPUT
END

SET @TCgsAcct       = NULL
SET @TCgsAcctUnit1 = NULL
SET @TCgsAcctUnit2 = NULL
SET @TCgsAcctUnit3 = NULL
SET @TCgsAcctUnit4 = NULL
SET @TCgsLbrAcct   = NULL
SET @TCgsLbrAcctUnit1 = NULL
SET @TCgsLbrAcctUnit2 = NULL
SET @TCgsLbrAcctUnit3 = NULL
SET @TCgsLbrAcctUnit4 = NULL
SET @TCgsFovhdAcct = NULL
SET @TCgsFovhdAcctUnit1 = NULL
SET @TCgsFovhdAcctUnit2 = NULL
SET @TCgsFovhdAcctUnit3 = NULL
SET @TCgsFovhdAcctUnit4 = NULL
SET @TCgsVovhdAcct = NULL
SET @TCgsVovhdAcctUnit1 = NULL
SET @TCgsVovhdAcctUnit2 = NULL
SET @TCgsVovhdAcctUnit3 = NULL
SET @TCgsVovhdAcctUnit4 = NULL
SET @TCgsOutAcct   = NULL
SET @TCgsOutAcctUnit1 = NULL
SET @TCgsOutAcctUnit2 = NULL
SET @TCgsOutAcctUnit3 = NULL
SET @TCgsOutAcctUnit4 = NULL
SET @ItemTaxFreeMatl = 0

if @CoEndUserType IS NOT NULL
BEGIN
   IF @CoShipmentApprovalRequired = 0
   BEGIN
       select
       @EndtypeRowPointer = endtype.RowPointer
      ,@EndtypeCgsMatlAcct = endtype.cgs_matl_acct
      ,@EndtypeCgsMatlAcctUnit1 = endtype.cgs_matl_acct_unit1
      ,@EndtypeCgsMatlAcctUnit2 = endtype.cgs_matl_acct_unit2
      ,@EndtypeCgsMatlAcctUnit3 = endtype.cgs_matl_acct_unit3
      ,@EndtypeCgsMatlAcctUnit4 = endtype.cgs_matl_acct_unit4
      ,@EndtypeCgsLbrAcct = endtype.cgs_lbr_acct
      ,@EndtypeCgsLbrAcctUnit1 = endtype.cgs_lbr_acct_unit1
      ,@EndtypeCgsLbrAcctUnit2 = endtype.cgs_lbr_acct_unit2
      ,@EndtypeCgsLbrAcctUnit3 = endtype.cgs_lbr_acct_unit3
      ,@EndtypeCgsLbrAcctUnit4 = endtype.cgs_lbr_acct_unit4
      ,@EndtypeCgsFovhdAcct = endtype.cgs_fovhd_acct
      ,@EndtypeCgsFovhdAcctUnit1 = endtype.cgs_fovhd_acct_unit1
      ,@EndtypeCgsFovhdAcctUnit2 = endtype.cgs_fovhd_acct_unit2
      ,@EndtypeCgsFovhdAcctUnit3 = endtype.cgs_fovhd_acct_unit3
      ,@EndtypeCgsFovhdAcctUnit4 = endtype.cgs_fovhd_acct_unit4
      ,@EndtypeCgsVovhdAcct = endtype.cgs_vovhd_acct
      ,@EndtypeCgsVovhdAcctUnit1 = endtype.cgs_vovhd_acct_unit1
      ,@EndtypeCgsVovhdAcctUnit2 = endtype.cgs_vovhd_acct_unit2
      ,@EndtypeCgsVovhdAcctUnit3 = endtype.cgs_vovhd_acct_unit3
      ,@EndtypeCgsVovhdAcctUnit4 = endtype.cgs_vovhd_acct_unit4
      ,@EndtypeCgsOutAcct = endtype.cgs_out_acct
      ,@EndtypeCgsOutAcctUnit1 = endtype.cgs_out_acct_unit1
      ,@EndtypeCgsOutAcctUnit2 = endtype.cgs_out_acct_unit2
      ,@EndtypeCgsOutAcctUnit3 = endtype.cgs_out_acct_unit3
      ,@EndtypeCgsOutAcctUnit4 = endtype.cgs_out_acct_unit4
      from endtype with (readuncommitted)
      where endtype.end_user_type = @CoEndUserType
   END
   ELSE
   BEGIN
       select
       @EndtypeRowPointer = endtype.RowPointer
      ,@EndtypeCgsMatlAcct = endtype.cgs_in_proc_matl_acct
      ,@EndtypeCgsMatlAcctUnit1 = endtype.cgs_in_proc_matl_acct_unit1
      ,@EndtypeCgsMatlAcctUnit2 = endtype.cgs_in_proc_matl_acct_unit2
      ,@EndtypeCgsMatlAcctUnit3 = endtype.cgs_in_proc_matl_acct_unit3
      ,@EndtypeCgsMatlAcctUnit4 = endtype.cgs_in_proc_matl_acct_unit4
      ,@EndtypeCgsLbrAcct = endtype.cgs_in_proc_lbr_acct
      ,@EndtypeCgsLbrAcctUnit1 = endtype.cgs_in_proc_lbr_acct_unit1
      ,@EndtypeCgsLbrAcctUnit2 = endtype.cgs_in_proc_lbr_acct_unit2
      ,@EndtypeCgsLbrAcctUnit3 = endtype.cgs_in_proc_lbr_acct_unit3
      ,@EndtypeCgsLbrAcctUnit4 = endtype.cgs_in_proc_lbr_acct_unit4
      ,@EndtypeCgsFovhdAcct = endtype.cgs_in_proc_fovhd_acct
      ,@EndtypeCgsFovhdAcctUnit1 = endtype.cgs_in_proc_fovhd_acct_unit1
      ,@EndtypeCgsFovhdAcctUnit2 = endtype.cgs_in_proc_fovhd_acct_unit2
      ,@EndtypeCgsFovhdAcctUnit3 = endtype.cgs_in_proc_fovhd_acct_unit3
      ,@EndtypeCgsFovhdAcctUnit4 = endtype.cgs_in_proc_fovhd_acct_unit4
      ,@EndtypeCgsVovhdAcct = endtype.cgs_in_proc_vovhd_acct
      ,@EndtypeCgsVovhdAcctUnit1 = endtype.cgs_in_proc_vovhd_acct_unit1
      ,@EndtypeCgsVovhdAcctUnit2 = endtype.cgs_in_proc_vovhd_acct_unit2
      ,@EndtypeCgsVovhdAcctUnit3 = endtype.cgs_in_proc_vovhd_acct_unit3
      ,@EndtypeCgsVovhdAcctUnit4 = endtype.cgs_in_proc_vovhd_acct_unit4
      ,@EndtypeCgsOutAcct = endtype.cgs_in_proc_out_acct
      ,@EndtypeCgsOutAcctUnit1 = endtype.cgs_in_proc_out_acct_unit1
      ,@EndtypeCgsOutAcctUnit2 = endtype.cgs_in_proc_out_acct_unit2
      ,@EndtypeCgsOutAcctUnit3 = endtype.cgs_in_proc_out_acct_unit3
      ,@EndtypeCgsOutAcctUnit4 = endtype.cgs_in_proc_out_acct_unit4
      from endtype with (readuncommitted)
      where endtype.end_user_type = @CoEndUserType
   END

   if @@rowcount <> 1
      set @EndtypeRowPointer = null

   if (@EndtypeRowPointer is not null)
   BEGIN
      if @EndtypeCgsMatlAcct IS NOT NULL
      BEGIN
         SET @TCgsAcct = @EndtypeCgsMatlAcct
         SET @TCgsAcctUnit1 = @EndtypeCgsMatlAcctUnit1
         SET @TCgsAcctUnit2 = @EndtypeCgsMatlAcctUnit2
         SET @TCgsAcctUnit3 = @EndtypeCgsMatlAcctUnit3
         SET @TCgsAcctUnit4 = @EndtypeCgsMatlAcctUnit4
      END

      if @EndtypeCgsLbrAcct IS NOT NULL
      BEGIN
         SET @TCgsLbrAcct = @EndtypeCgsLbrAcct
         SET @TCgsLbrAcctUnit1 = @EndtypeCgsLbrAcctUnit1
         SET @TCgsLbrAcctUnit2 = @EndtypeCgsLbrAcctUnit2
         SET @TCgsLbrAcctUnit3 = @EndtypeCgsLbrAcctUnit3
         SET @TCgsLbrAcctUnit4 = @EndtypeCgsLbrAcctUnit4
      END

      if @EndtypeCgsFovhdAcct IS NOT NULL
      BEGIN
         SET @TCgsFovhdAcct = @EndtypeCgsFovhdAcct
         SET @TCgsFovhdAcctUnit1 = @EndtypeCgsFovhdAcctUnit1
         SET @TCgsFovhdAcctUnit2 = @EndtypeCgsFovhdAcctUnit2
         SET @TCgsFovhdAcctUnit3 = @EndtypeCgsFovhdAcctUnit3
         SET @TCgsFovhdAcctUnit4 = @EndtypeCgsFovhdAcctUnit4
      END

      if @EndtypeCgsVovhdAcct IS NOT NULL
      BEGIN
         SET @TCgsVovhdAcct = @EndtypeCgsVovhdAcct
         SET @TCgsVovhdAcctUnit1 = @EndtypeCgsVovhdAcctUnit1
         SET @TCgsVovhdAcctUnit2 = @EndtypeCgsVovhdAcctUnit2
         SET @TCgsVovhdAcctUnit3 = @EndtypeCgsVovhdAcctUnit3
         SET @TCgsVovhdAcctUnit4 = @EndtypeCgsVovhdAcctUnit4
      END

      if @EndtypeCgsOutAcct IS NOT NULL
      BEGIN
         SET @TCgsOutAcct = @EndtypeCgsOutAcct
         SET @TCgsOutAcctUnit1 = @EndtypeCgsOutAcctUnit1
         SET @TCgsOutAcctUnit2 = @EndtypeCgsOutAcctUnit2
         SET @TCgsOutAcctUnit3 = @EndtypeCgsOutAcctUnit3
         SET @TCgsOutAcctUnit4 = @EndtypeCgsOutAcctUnit4
      END
   END
END

select
 @CustaddrCurrCode = custaddr.curr_code
,@CustaddrCustNum = custaddr.cust_num
from custaddr
where custaddr.cust_num = @CoCustNum
   AND custaddr.cust_seq = @CoCustSeq
if @@rowcount <> 1
begin
   exec @Severity = dbo.MsgAppSp @__BufferError OUTPUT, 'E=UniqueRecordNotFound'
      , '@custaddr'
      , @ObjectName

   exec dbo.RaiseErrorSp @__BufferError, 16, 1
end

select @CustomerPrintPackInv = print_pack_inv
from customer
where customer.cust_num = @CoCustNum
and customer.cust_seq = 0

select
 @CurrencyPlaces = currency.places
, @CurrencyPlacesCp = currency.places_cp
from currency with (readuncommitted)
where currency.curr_code = @CustaddrCurrCode
if @@rowcount <> 1
begin
   exec @Severity = dbo.MsgAppSp @__BufferError OUTPUT, 'E=UniqueRecordNotFound'
      , '@currency'
      , @ObjectName

   exec dbo.RaiseErrorSp @__BufferError, 16, 1
end

SET @TPlaces = @CurrencyPlaces

select
 @CoitemRowPointer = coitem.RowPointer
,@CoitemStat = coitem.stat
,@CoitemWhse = coitem.whse
,@CoitemPrice = coitem.price
,@CoitemDisc = coitem.disc
,@CoitemEcCode = coitem.ec_code
,@CoitemExportValue = coitem.export_value
,@CoitemTransNat = coitem.trans_nat
,@CoitemTransNat2 = coitem.trans_nat_2
,@CoitemCommCode = coitem.comm_code
,@CoitemSupplQtyConvFactor = coitem.suppl_qty_conv_factor
,@CoitemUnitWeight = coitem.unit_weight
,@CoitemProcessInd = coitem.process_ind
,@CoitemDelterm = coitem.delterm
,@CoitemOrigin = coitem.origin
,@CoitemTransport = coitem.transport
,@CoitemCoNum = coitem.co_num
,@CoitemCoLine = coitem.co_line
,@CoitemCoRelease = coitem.co_release
,@CoitemConsNum = coitem.cons_num
,@CoitemItem = coitem.item
,@CoitemQtyShipped = coitem.qty_shipped
,@OrigCoitemQtyShipped = coitem.qty_shipped
,@CoitemCgsTotalLbr = coitem.cgs_total_lbr
,@CoitemCgsTotalMatl = coitem.cgs_total_matl
,@CoitemCgsTotalFovhd = coitem.cgs_total_fovhd
,@CoitemCgsTotalVovhd = coitem.cgs_total_vovhd
,@CoitemCgsTotalOut = coitem.cgs_total_out
,@CoitemCgsTotal = coitem.cgs_total
,@CoitemQtyOrdered = coitem.qty_ordered
,@CoitemQtyInvoiced = coitem.qty_invoiced
,@CoitemQtyReturned = coitem.qty_returned
,@CoitemPrgBillTot = coitem.prg_bill_tot
,@CoitemPrgBillApp = coitem.prg_bill_app
,@CoitemQtyPacked = coitem.qty_packed
,@CoitemQtyPicked = coitem.qty_picked
,@CoitemQtyReady = coitem.qty_ready
,@CoitemQtyRsvd = coitem.qty_rsvd
,@CoitemShipDate = coitem.ship_date
,@CoitemLbrCost = coitem.lbr_cost
,@CoitemMatlCost = coitem.matl_cost
,@CoitemFovhdCost = coitem.fovhd_cost
,@CoitemVovhdCost = coitem.vovhd_cost
,@CoitemOutCost = coitem.out_cost
,@CoitemCost = coitem.cost
,@CoitemUM = coitem.u_m
,@CoitemShipSite = coitem.ship_site
,@CoitemRefType = coitem.ref_type
,@CoitemRefNum = coitem.ref_num
,@CoitemCustItem = coitem.cust_item
,@CoItemTaxCode1 = coitem.tax_code1
,@CoItemTaxCode2 = coitem.tax_code2
from coitem WITH (UPDLOCK)
where coitem.co_num = @SCoNum
   and coitem.co_line = @SCoLine
   and coitem.co_release = @SCoRel
   and coitem.ship_site = @ParmsSite
if @@rowcount <> 1
   set @CoitemRowPointer = null

IF @CoitemRowPointer is null
BEGIN
   EXEC @Severity = dbo.MsgAppSp @Infobar OUTPUT, 'E=NoExistIs3'
      , '@coitem'
      , '@coitem.ship_site'
      , @ParmsSite
      , '@coitem.co_num'
      , @SCoNum
      , '@coitem.co_line'
      , @SCoLine
      , '@coitem.co_release'
      , @SCoRel

   GOTO EOF
end

IF CHARINDEX( @CoitemStat, 'OF') = 0
BEGIN
   EXEC @Severity = dbo.MsgAppSp @Infobar OUTPUT, 'E=NoExistIs3'
      , '@coitem'
      , '@coitem.stat'
      , '@:CoitemStatus:O:F'
      , '@coitem.co_num'
      , @SCoNum
      , '@coitem.co_line'
      , @SCoLine
      , '@coitem.co_release'
      , @SCoRel

   GOTO EOF
end
select
@ItemProductCode = item.product_code
,@ItemSerialTracked = item.serial_tracked
,@ItemTaxFreeMatl = Item.tax_free_matl
,@ItemItem = item.item
,@ItemCostMethod = item.cost_method
,@ItemUnitWeight = item.unit_weight
,@ItemLotTracked = item.lot_tracked
,@ItemCostType = item.cost_type
,@ItemUnitCost = item.unit_cost
,@ItemShelfLife = item.shelf_life
,@UM = item.u_m
, @ItemUWsPrice = item.u_ws_price
from item WITH (UPDLOCK)
where item.item = @SItem
IF @CostItemAtWhse = 1
   select
    @ItemRowPointer = itemwhse.RowPointer
   ,@ItemLbrCost = itemwhse.lbr_cost
   ,@ItemMatlCost = itemwhse.matl_cost
   ,@ItemFovhdCost = itemwhse.fovhd_cost
   ,@ItemVovhdCost = itemwhse.vovhd_cost
   ,@ItemOutCost = itemwhse.out_cost
   from itemwhse WITH (UPDLOCK)
   where itemwhse.item = @SItem
   and itemwhse.whse = @CoitemWhse
ELSE
   select
    @ItemRowPointer = item.RowPointer
   ,@ItemLbrCost = item.lbr_cost
   ,@ItemMatlCost = item.matl_cost
   ,@ItemFovhdCost = item.fovhd_cost
   ,@ItemVovhdCost = item.vovhd_cost
   ,@ItemOutCost = item.out_cost
   from item WITH (UPDLOCK)
   where item.item = @SItem
if @@rowcount <> 1
   set @ItemRowPointer = null

IF @ItemRowPointer is null
   SET @NonInventoryItem = 1

IF @NonInventoryItem = 1
   select
    @ItemProductCode = item.product_code
   ,@ItemItem = item.item
     from non_inventory_item as item WITH (UPDLOCK)
    where item.item = @SItem

IF @NonInventoryItem <> 1
BEGIN
   select
   @ProdcodeRowPointer = prodcode.RowPointer
   ,@ProdcodeMarkup = prodcode.markup
   ,@ProdcodeUnit = prodcode.unit
   ,@ProdcodeInvAdjAcct = prodcode.inv_adj_acct
   ,@ProdcodeInvAdjAcctUnit1 = prodcode.inv_adj_acct_unit1
   ,@ProdcodeInvAdjAcctUnit2 = prodcode.inv_adj_acct_unit2
   ,@ProdcodeInvAdjAcctUnit3 = prodcode.inv_adj_acct_unit3
   ,@ProdcodeInvAdjAcctUnit4 = prodcode.inv_adj_acct_unit4
   ,@ProdcodeProductCode = prodcode.product_code
   from prodcode with (readuncommitted)
   where prodcode.product_code = @ItemProductCode

   if @@rowcount <> 1
      set @ProdcodeRowPointer = null

   if @ProdcodeRowPointer is null
   BEGIN
      EXEC @Severity = dbo.MsgAppSp @Infobar OUTPUT, 'E=NoExistForIs1'
         , '@prodcode'
         , '@prodcode.product_code'
         , @ItemProductCode
         , '@item'
         , '@item.item'
         , @SItem

      GOTO EOF
   end
END

if @ItemSerialTracked <> 0
BEGIN
   SELECT @TQtyCheck = COUNT(*) FROM tmp_ser
      WHERE tmp_ser.SessionId = @SessionID
      and tmp_ser.ref_str = @SWorkkey

   SET @QTYINT = ROUND(@SQty, 0)

   IF @UM <> @CoitemUM
   BEGIN
     EXEC @Severity = dbo.GetumcfSp @CoitemUM, @SItem, '', '', @UOMConvFactor OUTPUT, @Infobar OUTPUT
     IF @Severity <> 0 RETURN @Severity

     EXEC @Severity = dbo.UomConvQtySp @SQty, @UOMConvFactor, 'From Base', @SQtyConv OUTPUT, @Infobar OUTPUT
     IF @Severity <> 0 RETURN @Severity

     SET @QTYINT = ROUND(@SQtyConv, 0)
   END

   IF @QTYINT <> @TQtyCheck and - @QTYINT <> @TQtyCheck
   BEGIN
      EXEC @Severity = dbo.MsgAppSp @Infobar OUTPUT, 'E=IsCompare<>1'
         , '@serial'
         , '@coitem.qty_shipped'
         , '@item'
         , '@item.item'
         , @SItem

      GOTO EOF
   end
end

/* Check that if we are doing a Auto Create PO-CO update PO on demanding site that
   and the item is serial or lot tracked that that pre-assigned numbers are available */
IF @CoDemandingSitePoNum IS NOT NULL
begin
   SELECT @SCoNum = po_all.source_site_co_num
   , @PoAllAutoReceiveDemandingSitePo = po_all.auto_receive_demanding_site_po
   FROM po_all with (readuncommitted)
   WHERE po_all.site_ref = @CoDemandingSite
   AND po_all.source_site_co_num = @SCoNum

   IF @SCoNum IS NOT NULL and @PoAllAutoReceiveDemandingSitePo = 1
   BEGIN
   Declare @DemandingSiteItemSerialTracked ListYesNoType,
           @DemandingSiteItemLotTracked    ListYesNoType

   select  @DemandingSiteItemSerialTracked = item_all.serial_tracked
          ,@DemandingSiteItemLotTracked = item_all.lot_tracked
         from item_all WITH (UPDLOCK)
         where item_all.item = @SItem
           and item_all.site_ref = @CoDemandingSite

   IF @DemandingSiteItemSerialTracked IS NULL
      SET @DemandingSiteItemSerialTracked = 0

   IF @DemandingSiteItemLotTracked IS NULL
      SET @DemandingSiteItemLotTracked = 0

      IF @DemandingSiteItemSerialTracked = 1
      BEGIN
         -- For this PO for this item sum up all of the pre-assigned serial numbers
         select @PreAssignCount = Count(*)
         from serial_all with (readuncommitted)
            INNER JOIN po_all with (readuncommitted) ON
               po_all.po_num = serial_all.ref_num
               AND po_all.site_ref = serial_all.site_ref
               AND po_all.source_site_co_num = @SCoNum
               AND po_all.site_ref = @CoDemandingSite
            INNER JOIN poitem_all with (readuncommitted) ON
               poitem_all.po_num = po_all.po_num
               AND poitem_all.site_ref = serial_all.site_ref
               AND poitem_all.po_line = @SCoLine
               AND poitem_all.po_release = serial_all.ref_release
         where serial_all.stat = 'P'
         AND serial_all.ref_type = 'P'

         IF @SQty > @PreAssignCount
         BEGIN
            EXEC @Severity = dbo.MsgAppSp @Infobar OUTPUT, 'E=IsCompare<>1'
               , '@serial'
               , '@coitem.qty_shipped'
               , '@item'
               , '@item.item'
               , @SItem

            GOTO EOF
         END
      END

      IF @DemandingSiteItemLotTracked = 1
      BEGIN
          -- For this PO for this item sum up all of the pre-assigned Lot numbers
         SELECT @PreAssignCount = COUNT(*)
         FROM preassigned_lot_all with (readuncommitted)
            INNER JOIN po_all with (readuncommitted) ON po_all.po_num = preassigned_lot_all.ref_num
               AND po_all.site_ref = preassigned_lot_all.site_ref
               AND po_all.source_site_co_num = @SCoNum
               AND po_all.site_ref = @CoDemandingSite
            INNER JOIN poitem_all with (readuncommitted) ON poitem_all.po_num = po_all.po_num
               AND poitem_all.po_line = preassigned_lot_all.ref_line_suf
               AND poitem_all.po_release = preassigned_lot_all.ref_release
               AND poitem_all.site_ref = preassigned_lot_all.site_ref
         WHERE preassigned_lot_all.ref_type = 'P'
         AND preassigned_lot_all.ref_line_suf = @SCoLine
         AND preassigned_lot_all.qty_received = 0

         IF @PreAssignCount = 0
         BEGIN
            EXEC @Severity = dbo.MsgAppSp @Infobar OUTPUT, 'E=IsCompare<>1'
               , '@lot'
               , '@coitem.qty_shipped'
               , '@item'
               , '@item.item'
               , @SItem

            GOTO EOF
         END
      END
   END
end

SET @UOMConvFactor = 0

IF @CoShipmentApprovalRequired = 0
BEGIN
   SELECT
       @DistacctRowPointer = distacct.RowPointer
      ,@DistacctCgsAcct = distacct.cgs_acct
      ,@DistacctCgsAcctUnit1 = distacct.cgs_acct_unit1
      ,@DistacctCgsAcctUnit2 = distacct.cgs_acct_unit2
      ,@DistacctCgsAcctUnit3 = distacct.cgs_acct_unit3
      ,@DistacctCgsAcctUnit4 = distacct.cgs_acct_unit4
      ,@DistacctCgsLbrAcct = distacct.cgs_lbr_acct
      ,@DistacctCgsLbrAcctUnit1 = distacct.cgs_lbr_acct_unit1
      ,@DistacctCgsLbrAcctUnit2 = distacct.cgs_lbr_acct_unit2
      ,@DistacctCgsLbrAcctUnit3 = distacct.cgs_lbr_acct_unit3
      ,@DistacctCgsLbrAcctUnit4 = distacct.cgs_lbr_acct_unit4
      ,@DistacctCgsFovhdAcct = distacct.cgs_fovhd_acct
      ,@DistacctCgsFovhdAcctUnit1 = distacct.cgs_fovhd_acct_unit1
      ,@DistacctCgsFovhdAcctUnit2 = distacct.cgs_fovhd_acct_unit2
      ,@DistacctCgsFovhdAcctUnit3 = distacct.cgs_fovhd_acct_unit3
      ,@DistacctCgsFovhdAcctUnit4 = distacct.cgs_fovhd_acct_unit4
      ,@DistacctCgsVovhdAcct = distacct.cgs_vovhd_acct
      ,@DistacctCgsVovhdAcctUnit1 = distacct.cgs_vovhd_acct_unit1
      ,@DistacctCgsVovhdAcctUnit2 = distacct.cgs_vovhd_acct_unit2
      ,@DistacctCgsVovhdAcctUnit3 = distacct.cgs_vovhd_acct_unit3
      ,@DistacctCgsVovhdAcctUnit4 = distacct.cgs_vovhd_acct_unit4
      ,@DistacctCgsOutAcct = distacct.cgs_out_acct
      ,@DistacctCgsOutAcctUnit1 = distacct.cgs_out_acct_unit1
      ,@DistacctCgsOutAcctUnit2 = distacct.cgs_out_acct_unit2
      ,@DistacctCgsOutAcctUnit3 = distacct.cgs_out_acct_unit3
      ,@DistacctCgsOutAcctUnit4 = distacct.cgs_out_acct_unit4
      ,@DistacctInvMatlAcct = distacct.inv_acct
      ,@DistacctInvMatlAcctUnit1 = distacct.inv_acct_unit1
      ,@DistacctInvMatlAcctUnit2 = distacct.inv_acct_unit2
      ,@DistacctInvMatlAcctUnit3 = distacct.inv_acct_unit3
      ,@DistacctInvMatlAcctUnit4 = distacct.inv_acct_unit4
   FROM distacct with (readuncommitted)
   WHERE distacct.RowPointer = dbo.FndDist(@ItemItem, @CoitemWhse)
END
ELSE
BEGIN
   SELECT
       @DistacctRowPointer = distacct.RowPointer
      ,@DistacctCgsAcct = distacct.cgs_in_proc_matl_acct
      ,@DistacctCgsAcctUnit1 = distacct.cgs_in_proc_matl_acct_unit1
      ,@DistacctCgsAcctUnit2 = distacct.cgs_in_proc_matl_acct_unit2
      ,@DistacctCgsAcctUnit3 = distacct.cgs_in_proc_matl_acct_unit3
      ,@DistacctCgsAcctUnit4 = distacct.cgs_in_proc_matl_acct_unit4
      ,@DistacctCgsLbrAcct = distacct.cgs_in_proc_lbr_acct
      ,@DistacctCgsLbrAcctUnit1 = distacct.cgs_in_proc_lbr_acct_unit1
      ,@DistacctCgsLbrAcctUnit2 = distacct.cgs_in_proc_lbr_acct_unit2
      ,@DistacctCgsLbrAcctUnit3 = distacct.cgs_in_proc_lbr_acct_unit3
      ,@DistacctCgsLbrAcctUnit4 = distacct.cgs_in_proc_lbr_acct_unit4
      ,@DistacctCgsFovhdAcct = distacct.cgs_in_proc_fovhd_acct
      ,@DistacctCgsFovhdAcctUnit1 = distacct.cgs_in_proc_fovhd_acct_unit1
      ,@DistacctCgsFovhdAcctUnit2 = distacct.cgs_in_proc_fovhd_acct_unit2
      ,@DistacctCgsFovhdAcctUnit3 = distacct.cgs_in_proc_fovhd_acct_unit3
      ,@DistacctCgsFovhdAcctUnit4 = distacct.cgs_in_proc_fovhd_acct_unit4
      ,@DistacctCgsVovhdAcct = distacct.cgs_in_proc_vovhd_acct
      ,@DistacctCgsVovhdAcctUnit1 = distacct.cgs_in_proc_vovhd_acct_unit1
      ,@DistacctCgsVovhdAcctUnit2 = distacct.cgs_in_proc_vovhd_acct_unit2
      ,@DistacctCgsVovhdAcctUnit3 = distacct.cgs_in_proc_vovhd_acct_unit3
      ,@DistacctCgsVovhdAcctUnit4 = distacct.cgs_in_proc_vovhd_acct_unit4
      ,@DistacctCgsOutAcct = distacct.cgs_in_proc_out_acct
      ,@DistacctCgsOutAcctUnit1 = distacct.cgs_in_proc_out_acct_unit1
      ,@DistacctCgsOutAcctUnit2 = distacct.cgs_in_proc_out_acct_unit2
      ,@DistacctCgsOutAcctUnit3 = distacct.cgs_in_proc_out_acct_unit3
      ,@DistacctCgsOutAcctUnit4 = distacct.cgs_in_proc_out_acct_unit4
      ,@DistacctInvMatlAcct = distacct.inv_in_proc_acct
      ,@DistacctInvMatlAcctUnit1 = distacct.lbr_in_proc_acct_unit1
      ,@DistacctInvMatlAcctUnit2 = distacct.lbr_in_proc_acct_unit2
      ,@DistacctInvMatlAcctUnit3 = distacct.lbr_in_proc_acct_unit3
      ,@DistacctInvMatlAcctUnit4 = distacct.lbr_in_proc_acct_unit4
   FROM distacct with (readuncommitted)
   WHERE distacct.RowPointer = dbo.FndDist(@ItemItem, @CoitemWhse)
END

IF @@rowcount <> 1
   SET @DistacctRowPointer = null

IF @DistacctRowPointer is null and @CoitemCost != 0
BEGIN
   EXEC @Severity = dbo.MsgAppSp @Infobar OUTPUT, 'I=NoExistForIsOrIs1'
      , '@distacct'
      , '@distacct.product_code'
      , @ItemProductCode
      , '@distacct.whse'
      , @CoitemWhse
      , '@item'
      , '@item.item'
      , @SItem

   GOTO EOF
END
ELSE
BEGIN
   IF @TCgsAcct IS NULL
   BEGIN
      SET @TCgsAcct = @DistacctCgsAcct
      SET @TCgsAcctUnit1 = @DistacctCgsAcctUnit1
      SET @TCgsAcctUnit2 = @DistacctCgsAcctUnit2
      SET @TCgsAcctUnit3 = @DistacctCgsAcctUnit3
      SET @TCgsAcctUnit4 = @DistacctCgsAcctUnit4
   END

   IF @TCgsLbrAcct IS NULL
   BEGIN
      SET @TCgsLbrAcct = @DistacctCgsLbrAcct
      SET @TCgsLbrAcctUnit1 = @DistacctCgsLbrAcctUnit1
      SET @TCgsLbrAcctUnit2 = @DistacctCgsLbrAcctUnit2
      SET @TCgsLbrAcctUnit3 = @DistacctCgsLbrAcctUnit3
      SET @TCgsLbrAcctUnit4 = @DistacctCgsLbrAcctUnit4
   END

   IF @TCgsFovhdAcct IS NULL
   BEGIN
      SET @TCgsFovhdAcct = @DistacctCgsFovhdAcct
      SET @TCgsFovhdAcctUnit1 = @DistacctCgsFovhdAcctUnit1
      SET @TCgsFovhdAcctUnit2 = @DistacctCgsFovhdAcctUnit2
      SET @TCgsFovhdAcctUnit3 = @DistacctCgsFovhdAcctUnit3
      SET @TCgsFovhdAcctUnit4 = @DistacctCgsFovhdAcctUnit4
   END

   IF @TCgsVovhdAcct IS NULL
   BEGIN
      SET @TCgsVovhdAcct = @DistacctCgsVovhdAcct
      SET @TCgsVovhdAcctUnit1 = @DistacctCgsVovhdAcctUnit1
      SET @TCgsVovhdAcctUnit2 = @DistacctCgsVovhdAcctUnit2
      SET @TCgsVovhdAcctUnit3 = @DistacctCgsVovhdAcctUnit3
      SET @TCgsVovhdAcctUnit4 = @DistacctCgsVovhdAcctUnit4
   END

   IF @TCgsOutAcct IS NULL
   BEGIN
      SET @TCgsOutAcct = @DistacctCgsOutAcct
      SET @TCgsOutAcctUnit1 = @DistacctCgsOutAcctUnit1
      SET @TCgsOutAcctUnit2 = @DistacctCgsOutAcctUnit2
      SET @TCgsOutAcctUnit3 = @DistacctCgsOutAcctUnit3
      SET @TCgsOutAcctUnit4 = @DistacctCgsOutAcctUnit4
   END
END

IF @NonInventoryItem <> 1
BEGIN
   SELECT
    @ItemwhseQtyOnHand = itemwhse.qty_on_hand
   ,@ItemwhseQtyRsvdCo = itemwhse.qty_rsvd_co
   ,@ItemwhseQtyAllocCo = itemwhse.qty_alloc_co
   ,@ItemwhseCycleType = itemwhse.cycle_type
   ,@ItemwhseCycleFlag = itemwhse.cycle_flag
   ,@ItemwhseQtySoldYtd = itemwhse.qty_sold_ytd
   ,@ItemwhseQtyMrb = itemwhse.qty_mrb
   ,@ItemwhseRowPointer = itemwhse.RowPointer
   FROM itemwhse WITH (UPDLOCK)
   WHERE itemwhse.item = @ItemItem
      AND itemwhse.whse = @CoitemWhse
   IF @@rowcount <> 1
   BEGIN
      EXEC @Severity = dbo.MsgAppSp @__BufferError OUTPUT, 'E=UniqueRecordNotFound'
         , '@itemwhse'
         , @ObjectName

      EXEC dbo.RaiseErrorSp @__BufferError, 16, 1
   END
END

SET @DiscPrice =
   CASE WHEN @CoType = 'B'
      then @CoitemPrice
      else
         (CASE WHEN @CoParmsUseAltPriceCalc = 1 THEN
             round((@CoitemPrice * (1 - @CoitemDisc / 100)), @CurrencyPlaces)
          ELSE
             (@CoitemPrice * (1 - @CoitemDisc / 100))
          END)
   END

SET @TShipPrice = round(@SQty * @DiscPrice, @CurrencyPlaces)

SET @TShipPrice = @TShipPrice - round(@TShipPrice * (@CoDisc / 100), @CurrencyPlaces)

/* update LCR */
if @CoLcrNum IS NOT NULL
BEGIN
   select
    @CustLcrRowPointer = cust_lcr.RowPointer
   ,@CustLcrCurrCode = cust_lcr.curr_code
   ,@CustLcrShipValue = cust_lcr.ship_value
   from cust_lcr WITH (UPDLOCK)
   where cust_lcr.cust_num = @CoCustNum and
      cust_lcr.lcr_num = @CoLcrNum

   if @@rowcount <> 1
      set @CustLcrRowPointer = null

   if (@CustLcrRowPointer is not null)
   BEGIN
      SET @TLcrShipPrice = @TShipPrice

      declare @CusttypeTaxablePrice TaxablePriceType
      if isnull(@ItemUWsPrice, 0) > 0
         SELECT
           @CusttypeTaxablePrice = cut.taxable_price
         FROM custtype AS cut, customer AS cus, co AS co WITH (READUNCOMMITTED)
         WHERE co.co_num = @SCoNum
         AND   cus.cust_num = co.cust_num
         AND   cus.cust_seq = 0
         AND   cut.cust_type = ISNULL(cus.cust_type, NCHAR(1))

      EXEC @Severity = dbo.UseTmpTaxTablesSp @SessionId, null/*@ReleaseTmpTaxTables OUTPUT*/, @Infobar OUTPUT
      EXEC @Severity = dbo.TaxBaseSp
        'R'               -- @PInvType
      , 'I'               -- @PType
      , @CoitemTaxCode1   -- @PTaxCode1
      , @CoitemTaxCode2   -- @PTaxCode2
      , @TLcrShipPrice  -- @PAmount
      , 0   -- @PAmountToApply
      , @TLcrShipPrice    -- @PUndiscAmount
      , @ItemUWsPrice     -- @PUWsPrice
      , @CusttypeTaxablePrice -- @PTaxablePrice
      , @SQty       -- @PQtyInvoiced
      , @CustaddrCurrCode -- @PCurrCode
      , NULL              -- @PInvDate
      , @CoExchRate       -- @PExchRate
      , @Infobar OUTPUT
      , @pRefType       = 'O'
      , @pHdrPtr        = @CoRowPointer
      , @pLineRefType   = NULL
      , @pLinePtr       = @CoitemRowPointer

      EXEC @Severity = dbo.TaxCalcSp
        'R'            -- @PInvType Regular
      , @CoTaxCode1    -- @PTaxCode1
      , @CoTaxCode2    -- @PTaxCode2
      , 0--@CoFreight     -- @PFreight
      , null--@CoFrtTaxCode1 -- @PFrtTaxCode1
      , null--@CoFrtTaxCode2 -- @PFrtTaxCode2
      , 0--@CoMiscCharges -- @PMisc
      , null--@CoMscTaxCode1 -- @PMiscTaxCode1
      , null--@CoMscTaxCode2 -- @PMiscTaxCode2
      , NULL           -- @PInvDate
      , @CoTermsCode   -- @PTermsCode
      , @CoUseExchRate -- @PUseExchRate
      , @CustaddrCurrCode -- @PCurrCode
      , @CurrencyPlaces    -- @PPlaces
      , @CoExchRate    -- @PExchRate
      , @TempSalesTax  OUTPUT
      , @TempSalesTax2 OUTPUT
      , @Infobar       OUTPUT
      , @pRefType       = 'O'
      , @pHdrPtr        = @CoRowPointer

      EXEC dbo.ReleaseTmpTaxTablesSp @SessionId
  
      if @TempSalesTax is null
         set @TempSalesTax = 0
      if @TempSalesTax2 is null
         set @TempSalesTax2 = 0
      set @TLcrShipPrice = @TLcrShipPrice + @TempSalesTax + @TempSalesTax2
  
      if @CustLcrCurrCode <> @CustaddrCurrCode
      BEGIN
         SET @TRate = @CoExchRate
         EXEC @Severity = dbo.CurrCnvtSp
              @CurrCode =     @CustaddrCurrCode
            , @FromDomestic = 0
            , @UseBuyRate =   1
            , @RoundResult =  1
            , @Date =         NULL
            , @TRate =        @TRate  OUTPUT
            , @Infobar =      @Infobar OUTPUT
            , @Amount1 =      @TLcrShipPrice
            , @Result1 =      @TLcrShipPrice OUTPUT
            , @Site = @ParmsSite
            , @DomCurrCode = @CurrparmsCurrCode


         IF (@Severity >= 5)
            GOTO EOF
      end

      if @SReturn <> 0 and @SQty > 0
         SET @CustLcrShipValue = @CustLcrShipValue - @TLcrShipPrice
      else
         SET @CustLcrShipValue = @CustLcrShipValue + @TLcrShipPrice

      update cust_lcr
      set
       ship_value = @CustLcrShipValue
      , order_accum = order_accum + @TempSalesTax + @TempSalesTax2
      where RowPointer = @CustLcrRowPointer
   end
end

IF @ParmsEcReporting <> 0
AND @CoitemEcCode IS NOT NULL /* This will have the ssd ec code if we're in such a country. */
AND ISNULL(@CoitemProcessInd,'') <> '3'    /* Process Ind of 3 indicates service. do not create ssd record in this case.  */
BEGIN
   SET @TSQty = @SQty

   select @WhseEcCode = country.ssd_ec_code
   from whse_all with (readuncommitted)
      inner join country with (readuncommitted) on
         country.country = whse_all.country
   where whse_all.site_ref = @CoitemShipSite
   and whse_all.whse = @CoitemWhse

   select @CustomerEcCode = country.ssd_ec_code
   from custaddr with (readuncommitted)
      inner join country with (readuncommitted) on
         country.country = custaddr.country
   where custaddr.cust_num = @CoCustNum
   and custaddr.cust_seq = @CoCustSeq

   IF ISNULL(@WhseEcCode, '') = ISNULL(@CustomerEcCode, '')
   or ISNULL(@WhseEcCode, '') = ''
   or ISNULL(@CustomerEcCode, '') = ''
      GOTO SKIP_SSD

   -- This block was formerly co/co-t-ssd.p:
   select
    @TaxparmsTwoExchRates = taxparms.two_exch_rates
   from taxparms with (readuncommitted)
   if @@rowcount <> 1
   begin
      exec @Severity = dbo.MsgAppSp @__BufferError OUTPUT, 'E=UniqueRecordNotFound'
         , '@taxparms'
         , @ObjectName
      exec dbo.RaiseErrorSp @__BufferError, 16, 1
   end

   select
    @ReasonRowPointer = reason.RowPointer
   ,@ReasonTransIndicator = reason.trans_indicator
   ,@ReasonTransNat = reason.trans_nat
   ,@ReasonTransNat2 = reason.trans_nat_2
   ,@ReasonReasonCode = reason.reason_code
   from reason with (readuncommitted)
   where reason.reason_class = 'CO RETURN' and
      reason.reason_code = @SReasonCode

   if @@rowcount <> 1
      set @ReasonRowPointer = null

   select
    @CommodityRowPointer = commodity.RowPointer
   ,@CommoditySupplQtyReq = commodity.suppl_qty_req
   ,@CommodityCommCode = commodity.comm_code
   from commodity with (readuncommitted)
   where commodity.comm_code = @CoitemCommCode

   if @@rowcount <> 1
      set @CommodityRowPointer = null

   if (@CommodityRowPointer is not null)
   AND @CommoditySupplQtyReq <> 0
   AND (@CoitemSupplQtyConvFactor IS NULL or @CoitemSupplQtyConvFactor <= 0)
   BEGIN
      EXEC @Severity = dbo.MsgAppSp @Infobar OUTPUT, 'I=IsCompare1'
         , '@commodity.suppl_qty_req'
         , '@:ListYesNo:1'
         , '@commodity'
         , '@commodity.comm_code'
         , @CommodityCommCode

      EXEC @Severity = dbo.MsgAppSp @Infobar OUTPUT, 'E=MustCompare>'
         , '@coitem.suppl_qty_conv_factor'
         , '0'

      GOTO EOF
   end

   if @SReturn = 0 and @TSQty >= 0
   BEGIN
      /* Regular Shipment */
      SET @TCase = 'Regular' /* new co-ship */
      SET @TExportValue = @CoitemExportValue
      SET @TTransInd = 'D'
      SET @TTransNat = @CoitemTransNat
      SET @TTransNat2 = @CoitemTransNat2
   end
   else if @SReturn = 0 and @TSQty < 0 and @ReasonTransIndicator = 'D'
   BEGIN
      /* Negative Shipment to correct data entry */
      SET @TCase = 'Adjustment' /* adjust existing co-ship */
      SET @TExportValue = - @CoitemExportValue
      SET @TTransInd = @ReasonTransIndicator
      SET @TTransNat = @ReasonTransNat
      SET @TTransNat2 = @ReasonTransNat2
   END
   else if @SReturn = 0 and @TSQty < 0 and @ReasonTransIndicator = 'A'
   BEGIN
      /* Negative Shipment for returned part */
      SET @TCase = 'Adjustment'
      SET @TSQty = - @TSQty
      SET @TExportValue = @CoitemExportValue
      SET @TShipPrice   = - @TShipPrice
      SET @TTransInd = @ReasonTransIndicator
      SET @TTransNat = @ReasonTransNat
      SET @TTransNat2 = @ReasonTransNat2
   END
   else IF @SReturn <> 0 and @TSQty >= 0 and @ReasonTransIndicator = 'D'
   BEGIN
      /* Credit Return to correct data entry */
      SET @TCase = 'Adjustment'
      SET @TSQty = - @TSQty
      SET @TExportValue = - @CoitemExportValue
      SET @TShipPrice   = - @TShipPrice
      SET @TTransInd = @ReasonTransIndicator
      SET @TTransNat = @ReasonTransNat
      SET @TTransNat2 = @ReasonTransNat2
   END
   else IF @SReturn <> 0 and @TSQty >= 0 and @ReasonTransIndicator = 'A'
   BEGIN
      /* Credit Return for returned part */
      SET @TCase = 'Adjustment'
      SET @TExportValue = @CoitemExportValue
      SET @TTransInd = @ReasonTransIndicator
      SET @TTransNat = @ReasonTransNat
      SET @TTransNat2 = @ReasonTransNat2
   END
   else IF @SReturn <> 0 and @TSQty < 0 and @ReasonTransIndicator = 'A'
   BEGIN
      /* Negative Credit Return to correct data entry */
      SET @TCase = 'Adjustment'
      SET @TExportValue = - @CoitemExportValue
      SET @TTransInd = @ReasonTransIndicator
      SET @TTransNat = @ReasonTransNat
      SET @TTransNat2 = @ReasonTransNat2
   END
   else
   BEGIN
      BEGIN
         SET @MsgParm2 = '@:ListYesNo:' + CAST(@SReturn AS NCHAR)

         EXEC @MsgSeverity = dbo.MsgAppSp @Infobar OUTPUT, 'I=IsCompare'
            , '@tmp_ship.cr_return', @MsgParm2
         IF @MsgSeverity >= ISNULL(@Severity, 0)
            SET @Severity = @MsgSeverity
      END

      EXEC @Severity = dbo.MsgAppSp @Infobar OUTPUT, 'I=IsCompare1'
         , '@reason.trans_indicator'
         , @ReasonTransIndicator
         , '@reason'
         , '@reason.reason_code'
         , @ReasonReasonCode

      EXEC @Severity = dbo.MsgAppSp @Infobar OUTPUT, 'E=NoCompare<'
         , '@matltran.qty'
         , '0'

      GOTO EOF
   end

   SET @TRate = CASE WHEN @CoFixedRate <> 0 then @CoExchRate else NULL END

   if @TExportValue IS NULL or @TExportValue = 0
   BEGIN
      SET @TForValue = @TShipPrice

      IF @TaxparmsTwoExchRates <> 0
         EXEC @Severity = dbo.CurrCnvtSp
              @CurrCode =     @CustaddrCurrCode
            , @UseCustomsAndExciseRates = 1
            , @FromDomestic = 0
            , @UseBuyRate =   0
            , @RoundResult =  1
            , @Date =         @STransDate
            , @TRate =        @TRate  OUTPUT
            , @Infobar =      @Infobar   OUTPUT
            , @Amount1 =      @TForValue
            , @Result1 =      @TExportValue OUTPUT
            , @Site = @ParmsSite
            , @DomCurrCode = @CurrparmsCurrCode

        IF (@Severity >= 5)
           GOTO EOF
      ELSE
         EXEC @Severity = dbo.CurrCnvtSp
              @CurrCode =     @CustaddrCurrCode
            , @FromDomestic = 0
            , @UseBuyRate =   0
            , @RoundResult =  1
            , @Date =         @STransDate
            , @TRate =        @TRate  OUTPUT
            , @Infobar =      @Infobar   OUTPUT
            , @Amount1 =      @TForValue
            , @Result1 =      @TExportValue OUTPUT
            , @Site = @ParmsSite
            , @DomCurrCode = @CurrparmsCurrCode

         IF (@Severity >= 5)
           GOTO EOF
   end
   else
   BEGIN
      set @TForValue = @TExportValue * @TSQty
      IF @TaxparmsTwoExchRates <> 0
         EXEC @Severity = dbo.CurrCnvtSp
              @CurrCode =     @CustaddrCurrCode
            , @UseCustomsAndExciseRates = 1
            , @FromDomestic = 0
            , @UseBuyRate =   0
            , @RoundResult =  1
            , @Date =         @STransDate
            , @TRate =        @TRate  OUTPUT
            , @Infobar =      @Infobar   OUTPUT
            , @Amount1 =      @TForValue
            , @Result1 =      @TExportValue OUTPUT
            , @Site = @ParmsSite
            , @DomCurrCode = @CurrparmsCurrCode

        IF (@Severity >= 5)
           GOTO EOF
      ELSE
         EXEC @Severity = dbo.CurrCnvtSp
              @CurrCode =     @CustaddrCurrCode
            , @FromDomestic = 0
            , @UseBuyRate =   0
            , @RoundResult =  1
            , @Date =         @STransDate
            , @TRate =        @TRate  OUTPUT
            , @Infobar =      @Infobar   OUTPUT
            , @Amount1 =      @TForValue
            , @Result1 =      @TExportValue OUTPUT
            , @Site = @ParmsSite
            , @DomCurrCode = @CurrparmsCurrCode

        IF (@Severity >= 5)
           GOTO EOF
   end

   if @CoitemTransport is null
      select @CoitemTransport = shipcode.transport
      from shipcode with (readuncommitted)
      where shipcode.ship_code = @CoShipCode

   if @CoitemTransport is null
      select @CoitemTransport = whse_all.transport
      from whse_all with (readuncommitted)
      where whse_all.site_ref = @CoitemShipSite
      and whse_all.whse = @CoitemWhse

   set @SsdRowPointer = newid()
   SET @SsdTransDate      = @STransDate
   SET @SsdTransIndicator = @TTransInd
   SET @SsdRefType        = 'O' /* customer order */

   SET @SsdTransQty       = @TSQty
   SET @SsdUnitWeight     = @CoitemUnitWeight * @TSQty
   SET @SsdCurrCode       = @CustaddrCurrCode
   SET @SsdForeignValue   = @TForValue
   SET @SsdExchRate       = @TRate
   SET @SsdExportValue    = @TExportValue

   SET @SsdCommCode       = @CoitemCommCode
   SET @SsdTransNat       = @TTransNat
   SET @SsdTransNat2      = @TTransNat2
   SET @SsdProcessInd     = @CoitemProcessInd
   SET @SsdDelterm        = @CoitemDelterm
   SET @SsdOrigin         = @CoitemOrigin
   SET @SsdEcCode         = @CoitemEcCode
   SET @SsdTransport      = @CoitemTransport
   SET @SsdPrinted        = 0
   SET @SsdTaxDistrict    = NULL
   SET @SsdPortOfEntry    = NULL
   SET @SsdStatValue      = 0
   SET @SsdVendNum        = @CoCustNum
   SET @SsdRefNum         = @CoitemCoNum
   SET @SsdRefLineSuf     = @CoitemCoLine
   SET @SsdRefRelease     = @CoitemCoRelease

   IF @TCase = 'Regular'
   BEGIN
      /* Regular SSD Transaction */
      select top 1
       @CoShipRowPointer = co_ship.RowPointer
      ,@CoShipDateSeq = co_ship.date_seq
      ,@CoShipDoNum = co_ship.do_num
      ,@CoShipDoLine = co_ship.do_line
      ,@CoShipDoSeq = co_ship.do_seq
      ,@CoShipQtyInvoiced = co_ship.qty_invoiced
      ,@CoShipQtyReturned = co_ship.qty_returned
      ,@CoShipLbrCost = co_ship.lbr_cost
      ,@CoShipMatlCost = co_ship.matl_cost
      ,@CoShipFovhdCost = co_ship.fovhd_cost
      ,@CoShipVovhdCost = co_ship.vovhd_cost
      ,@CoShipOutCost = co_ship.out_cost
      ,@CoShipCost = co_ship.cost
      ,@CoShipCoNum = co_ship.co_num
      ,@CoShipCoLine = co_ship.co_line
      ,@CoShipCoRelease = co_ship.co_release
      ,@CoShipShipDate = co_ship.ship_date
      ,@CoShipQtyShipped = co_ship.qty_shipped
      ,@CoShipPrice = co_ship.price
      ,@CoShipUnitWeight = co_ship.unit_weight
      ,@CoShipByCons = co_ship.by_cons
      ,@CoShipShipmentId = co_ship.shipment_id
      from co_ship
      where co_ship.co_num = @CoitemCoNum and
         co_ship.co_line = @CoitemCoLine and
         co_ship.co_release = @CoitemCoRelease and
         co_ship.ship_date = @STransDate
      order by co_ship.date_seq desc
      if @@rowcount <> 1
         set @CoShipRowPointer = null

      SET @SsdDateSeq  = CASE WHEN (@CoShipRowPointer is not null) then @CoShipDateSeq + 1 else 1 END
      SET @SsdSupplQty = CASE WHEN @CommoditySupplQtyReq = 1
                                 THEN (@SQty * @CoitemUnitWeight * @ParmsEcConvFactor * @CoitemSupplQtyConvFactor)
                              ELSE 0
                         END
   end
   ELSE IF @TCase = 'Adjustment'
   BEGIN
      /* Adjustment to existing SSD transaction */
      /* We'll just throw the whole adjustment against the first co-ship we find...
       */
      if @ItemCostMethod = 'F'
      begin
         select top 1
          @CoShipRowPointer = co_ship.RowPointer
         ,@CoShipDateSeq = co_ship.date_seq
         ,@CoShipDoNum = co_ship.do_num
         ,@CoShipDoLine = co_ship.do_line
         ,@CoShipDoSeq = co_ship.do_seq
         ,@CoShipQtyInvoiced = co_ship.qty_invoiced
         ,@CoShipQtyReturned = co_ship.qty_returned
         ,@CoShipLbrCost = co_ship.lbr_cost
         ,@CoShipMatlCost = co_ship.matl_cost
         ,@CoShipFovhdCost = co_ship.fovhd_cost
         ,@CoShipVovhdCost = co_ship.vovhd_cost
         ,@CoShipOutCost = co_ship.out_cost
         ,@CoShipCost = co_ship.cost
         ,@CoShipCoNum = co_ship.co_num
         ,@CoShipCoLine = co_ship.co_line
         ,@CoShipCoRelease = co_ship.co_release
         ,@CoShipShipDate = co_ship.ship_date
         ,@CoShipQtyShipped = co_ship.qty_shipped
         ,@CoShipPrice = co_ship.price
         ,@CoShipUnitWeight = co_ship.unit_weight
         ,@CoShipByCons = co_ship.by_cons
         ,@CoShipShipmentId = co_ship.shipment_id
         from co_ship
         where co_ship.co_num = @CoitemCoNum and
            co_ship.co_line = @CoitemCoLine and
            co_ship.co_release = @CoitemCoRelease
         order by co_ship.ship_date asc, co_ship.date_seq asc
         if @@rowcount <> 1
            begin
            exec @Severity = dbo.MsgAppSp @__BufferError OUTPUT, 'E=UniqueRecordNotFound'
              , '@co_ship'
              , @ObjectName

            exec dbo.RaiseErrorSp @__BufferError, 16, 1
         end
      end
      else
      begin
         select top 1
          @CoShipRowPointer = co_ship.RowPointer
         ,@CoShipDateSeq = co_ship.date_seq
         ,@CoShipDoNum = co_ship.do_num
         ,@CoShipDoLine = co_ship.do_line
         ,@CoShipDoSeq = co_ship.do_seq
         ,@CoShipQtyInvoiced = co_ship.qty_invoiced
         ,@CoShipQtyReturned = co_ship.qty_returned
         ,@CoShipLbrCost = co_ship.lbr_cost
         ,@CoShipMatlCost = co_ship.matl_cost
         ,@CoShipFovhdCost = co_ship.fovhd_cost
         ,@CoShipVovhdCost = co_ship.vovhd_cost
         ,@CoShipOutCost = co_ship.out_cost
         ,@CoShipCost = co_ship.cost
         ,@CoShipCoNum = co_ship.co_num
         ,@CoShipCoLine = co_ship.co_line
         ,@CoShipCoRelease = co_ship.co_release
         ,@CoShipShipDate = co_ship.ship_date
         ,@CoShipQtyShipped = co_ship.qty_shipped
         ,@CoShipPrice = co_ship.price
         ,@CoShipUnitWeight = co_ship.unit_weight
         ,@CoShipByCons = co_ship.by_cons
         ,@CoShipShipmentId = co_ship.shipment_id
         from co_ship
         where co_ship.co_num = @CoitemCoNum and
            co_ship.co_line = @CoitemCoLine and
            co_ship.co_release = @CoitemCoRelease
         order by co_ship.ship_date desc, co_ship.date_seq desc
         if @@rowcount <> 1
         begin
            exec @Severity = dbo.MsgAppSp @__BufferError OUTPUT, 'E=UniqueRecordNotFound'
               , '@co_ship'
               , @ObjectName

            exec dbo.RaiseErrorSp @__BufferError, 16, 1
         end
      end

      SET @SsdDateSeq        = @CoShipDateSeq
      SET @SsdSupplQty       = CASE WHEN @CommoditySupplQtyReq = 1
                                 THEN (-@SQty * @CoitemUnitWeight * @ParmsEcConvFactor * @CoitemSupplQtyConvFactor)
                              ELSE 0
                         END
   END

   SET @SsdRefLineSuf = dbo.ExpandKyByType ('InvNumType',@SsdRefLineSuf)

   insert into ssd (RowPointer, trans_date, trans_indicator, ref_type, trans_qty, unit_weight
   , curr_code, foreign_value, exch_rate, export_value, comm_code, trans_nat, trans_nat_2,process_ind
   , delterm, origin, ec_code, transport, printed, tax_district, port_of_entry, stat_value
   , vend_num, ref_num, ref_line_suf, ref_release, date_seq, suppl_qty)
   values(@SsdRowPointer, @SsdTransDate, @SsdTransIndicator, @SsdRefType, @SsdTransQty, @SsdUnitWeight
   , @SsdCurrCode, @SsdForeignValue, @SsdExchRate, @SsdExportValue, @SsdCommCode, @SsdTransNat, @SsdTransNat2,@SsdProcessInd
   , @SsdDelterm, @SsdOrigin, @SsdEcCode, @SsdTransport, @SsdPrinted, @SsdTaxDistrict, @SsdPortOfEntry, @SsdStatValue
   , @SsdVendNum, @SsdRefNum, @SsdRefLineSuf, @SsdRefRelease, @SsdDateSeq, @SsdSupplQty)
end
SKIP_SSD:

if @SDoNum IS NOT NULL
begin
   select
    @DoHdrRowPointer = do_hdr.RowPointer
   ,@DoHdrCustNum = do_hdr.cust_num
   ,@DoHdrDoNum = do_hdr.do_num
   ,@DoHdrCustSeq = do_hdr.cust_seq
   ,@DoHdrStat = do_hdr.stat
   ,@DoHdrDoValue = do_hdr.do_value
   from do_hdr WITH (UPDLOCK)
   where do_hdr.do_num = @SDoNum
   if @@rowcount <> 1
      set @DoHdrRowPointer = null
end

select
  @AvgMatlCost  = round(sum(co_ship.qty_shipped * co_ship.matl_cost ) / sum(co_ship.qty_shipped), @XCurrencyPlacesCp)
, @AvgLbrCost   = round(sum(co_ship.qty_shipped * co_ship.lbr_cost  ) / sum(co_ship.qty_shipped), @XCurrencyPlacesCp)
, @AvgFovhdCost = round(sum(co_ship.qty_shipped * co_ship.fovhd_cost) / sum(co_ship.qty_shipped), @XCurrencyPlacesCp)
, @AvgVovhdCost = round(sum(co_ship.qty_shipped * co_ship.vovhd_cost) / sum(co_ship.qty_shipped), @XCurrencyPlacesCp)
, @AvgOutCost   = round(sum(co_ship.qty_shipped * co_ship.out_cost  ) / sum(co_ship.qty_shipped), @XCurrencyPlacesCp)
from co_ship
where co_ship.co_num = @CoitemCoNum
and co_ship.co_line = @CoitemCoLine
and co_ship.co_release = @CoitemCoRelease

/* UPDATE co-ship records */
if @SReturn = 0 and @SQty > 0
BEGIN
   select top 1
    @XCoShipRowPointer = x_co_ship.RowPointer
   ,@XCoShipDateSeq = x_co_ship.date_seq
   ,@XCoShipShipDate = x_co_ship.ship_date
   from co_ship  as x_co_ship
   where x_co_ship.co_num = @CoitemCoNum and
      x_co_ship.co_line = @CoitemCoLine and
      x_co_ship.co_release = @CoitemCoRelease and
      x_co_ship.ship_date = @STransDate
   order by x_co_ship.date_seq desc
   if @@rowcount <> 1
      set @XCoShipRowPointer = null

   SET @TDateSeq = CASE WHEN (@XCoShipRowPointer is not null) then @XCoShipDateSeq + 1 else 1 END
   SET @TRate = @CoExchRate

   EXEC @Severity = dbo.CurrCnvtSp
        @CurrCode =     @CustaddrCurrCode
      , @FromDomestic = 0
      , @UseBuyRate =   0
      , @RoundResult =  1
      , @Date =         @STransDate
      , @TRate =        @TRate  OUTPUT
      , @Infobar =      @Infobar OUTPUT
      , @Amount1 =      @TCost
      , @Result1 =      @TCost OUTPUT
      , @Site = @ParmsSite
      , @DomCurrCode = @CurrparmsCurrCode

   IF (@Severity >= 5)
      GOTO EOF

   set @CoShipRowPointer = newid()
   -- INITIALIZING VARS FOR TABLE INSERT
   SET @CoShipDoNum       = NULL
   SET @CoShipDoLine      = (0)
   SET @CoShipDoSeq       = (0)
   SET @CoShipQtyInvoiced = (0)
   SET @CoShipQtyReturned = (0)
   SET @CoShipLbrCost     = (0)
   SET @CoShipMatlCost    = (0)
   SET @CoShipFovhdCost   = (0)
   SET @CoShipVovhdCost   = (0)
   SET @CoShipOutCost     = (0)
   SET @CoShipCost         = (0)

   SET @CoShipCoNum = @CoitemCoNum
   SET @CoShipCoLine = @CoitemCoLine
   SET @CoShipCoRelease = @CoitemCoRelease
   SET @CoShipShipDate = @STransDate
   SET @CoShipDateSeq = @TDateSeq
   SET @CoShipQtyShipped = @SQty
   SET @CoShipPrice = @CoitemPrice
   SET @CoitemUnitWeight = CASE WHEN @ParmsECReporting <> 0 THEN @CoitemUnitWeight ELSE @ItemUnitWeight END
   SET @CoShipUnitWeight = @CoitemUnitWeight
   SET @CoShipByCons  = @SConsign
   SET @CoShipShipmentId = @ShipmentId

   insert into co_ship (RowPointer, co_num, co_line, co_release
   , ship_date, date_seq, qty_shipped, price, unit_weight, by_cons, shipment_id)
   values(@CoShipRowPointer, @CoShipCoNum, @CoShipCoLine, @CoShipCoRelease
   , @CoShipShipDate, @CoShipDateSeq, @CoShipQtyShipped, @CoShipPrice, @CoShipUnitWeight, @CoShipByCons, @CoShipShipmentId)

   SET @CoitemConsNum    = @CoitemConsNum + CASE WHEN @SConsign <> 0 THEN 1 ELSE 0 END

   if @SDoNum IS NOT NULL
   BEGIN
      if not (@DoHdrRowPointer is not null)
      BEGIN
         EXEC @Severity = dbo.MsgAppSp @Infobar OUTPUT, 'E=NoExist1'
            , '@do_hdr'
            , '@do_hdr.do_num'
            , @SDoNum

         GOTO EOF
      end

      if @DoHdrCustNum <> @CoCustNum
      BEGIN
         EXEC @Severity = dbo.MsgAppSp @Infobar OUTPUT, 'E=IsCompare<>1'
            , '@do_hdr.cust_num'
            , @CoCustNum
            , '@do_hdr'
            , '@do_hdr.do_num'
            , @DoHdrDoNum

         GOTO EOF
      end

      if @DoHdrCustSeq <> @CoCustSeq
      BEGIN
         EXEC @Severity = dbo.MsgAppSp @Infobar OUTPUT, 'E=IsCompare<>1'
            , '@do_hdr.cust_seq'
            , @CoCustSeq
            , '@do_hdr'
            , '@do_hdr.do_num'
            , @DoHdrDoNum

         GOTO EOF
      end

      if @DoHdrStat <> 'I'
      BEGIN
         EXEC @Severity = dbo.MsgAppSp @Infobar OUTPUT, 'E=IsCompare<>1'
            , '@do_hdr.stat'
            , '@:DoStatus:I'
            , '@do_hdr'
            , '@do_hdr.do_num'
            , @DoHdrDoNum

         GOTO EOF
      end

      if @SDoLine > 0
      BEGIN
         select
          @DoLineRowPointer = do_line.RowPointer
         ,@DoLineDoLine = do_line.do_line
         ,@DoLineDoNum = do_line.do_num
         from do_line
         where do_line.do_num = @DoHdrDoNum
            and do_line.do_line = @SDoLine
         if @@rowcount <> 1
            set @DoLineRowPointer = null

         if @DoLineRowPointer is null
         BEGIN
            EXEC @Severity = dbo.MsgAppSp @Infobar OUTPUT, 'E=NoExist2'
               , '@do_line'
               , '@do_line.do_num'
               , @DoHdrDoNum --'do_hdr.do_num'
               , '@do_line.do_line'
               , @SDoLine

            GOTO EOF
         end
      end
      else
      BEGIN
         select top 1
          @DoLineRowPointer = do_line.RowPointer
         ,@DoLineDoLine = do_line.do_line
         ,@DoLineDoNum = do_line.do_num
         from do_line
         where do_line.do_num = @DoHdrDoNum
         order by do_line.do_line desc
         if @@rowcount <> 1
            set @DoLineRowPointer = null

         if (@DoLineRowPointer is not null) and @DoLineDoLine >= 999
         BEGIN
            EXEC @Severity = dbo.MsgAppSp @Infobar OUTPUT, 'E=Exist2'
               , '@do_line'
               , '@do_line.do_num'
               , @DoLineDoNum
               , '@do_line.do_line'
               , @DoLineDoLine

            GOTO EOF
         end
    /* CBS need to check the do_line RowPointer before creating a new RowPointer. */
         DECLARE @NextDoLine DoLineType
         SET @NextDoLine = CASE WHEN (@DoLineRowPointer is not null) then @DoLineDoLine + 1 else 1 END

         set @DoLineRowPointer = newid()
         SET @DoLineDoNum = @DoHdrDoNum
         SET @DoLineDoLine = @NextDoLine

         insert into do_line (RowPointer, do_num, do_line)
         values(@DoLineRowPointer, @DoLineDoNum, @DoLineDoLine)

         update shipitem set do_line = @DoLineDoLine
            where batch_id   = @BatchId AND
                  co_num     = @SCoNum AND
                  co_line    = @SCoLine AND
                  co_release = @SCoRel
      end

      select top 1
       @DoSeqRowPointer = do_seq.RowPointer
      ,@DoSeqDoSeq = do_seq.do_seq
      ,@DoSeqDoNum = do_seq.do_num
      ,@DoSeqDoLine = do_seq.do_line
      ,@DoSeqRefNum = do_seq.ref_num
      ,@DoSeqRefLine = do_seq.ref_line
      ,@DoSeqRefRelease = do_seq.ref_release
      ,@DoSeqShipDate = do_seq.ship_date
      ,@DoSeqDateSeq = do_seq.date_seq
      from do_seq
      where do_seq.do_num = @DoLineDoNum
         and do_seq.do_line = @DoLineDoLine
      order by do_seq.do_seq desc
      if @@rowcount <> 1
         set @DoSeqRowPointer = null

      if (@DoSeqRowPointer is not null) and @DoSeqDoSeq >= 9999
      BEGIN
         EXEC @Severity = dbo.MsgAppSp @Infobar OUTPUT, 'E=Exist3'
            , '@do_seq'
            , '@do_seq.do_num'
            , @DoLineDoNum
            , '@do_seq.do_line'
            , @DoLineDoLine
            , '@do_seq.do_seq'
            , @DoSeqDoSeq

         GOTO EOF
      end

      DECLARE @NextDoSeq DoSeqType
      SET @NextDoSeq = CASE WHEN (@DoSeqRowPointer is not null) then @DoSeqDoSeq + 1 else 1 END


      set @DoSeqRowPointer = newid()
      SET @DoSeqDoNum = @DoLineDoNum
      SET @DoSeqDoLine = @DoLineDoLine
      SET @DoSeqDoSeq = @NextDoSeq
      SET @DoSeqRefNum = @CoShipCoNum
      SET @DoSeqRefLine = @CoShipCoLine
      SET @DoSeqRefRelease = @CoShipCoRelease
      SET @DoSeqShipDate = @CoShipShipDate
      SET @DoSeqDateSeq = @CoShipDateSeq

      insert into do_seq (RowPointer, do_num, do_line, do_seq
      , ref_num, ref_line, ref_release, ship_date, date_seq)
      values(@DoSeqRowPointer, @DoSeqDoNum, @DoSeqDoLine, @DoSeqDoSeq
      , @DoSeqRefNum, @DoSeqRefLine, @DoSeqRefRelease, @DoSeqShipDate, @DoSeqDateSeq)

      SET @CoShipDoNum = @DoLineDoNum
      SET @CoShipDoLine = @DoLineDoLine
      SET @CoShipDoSeq = @NextDoSeq

      update co_ship
      set
       do_num = @CoShipDoNum
      ,do_line = @CoShipDoLine
      ,do_seq = @CoShipDoSeq
      where RowPointer = @CoShipRowPointer

      exec @Severity = dbo.GetumcfSp
        @OtherUM = @CoitemUM
      , @Item = @ItemItem
      , @VendNum = @DoHdrCustNum
      , @Area = 'C'
      , @ConvFactor = @UomConvFactor OUTPUT
      , @Infobar = @Infobar OUTPUT
      if @Severity > 0 or @UomConvFactor is null
      begin
         set @Severity = 0
         set @CoShipPriceConv = @CoShipPrice
         set @CoShipQtyShippedConv = @CoShipQtyShipped
      end
      else
      begin
         set @CoShipQtyShippedConv = round(dbo.UomConvQty(@CoShipQtyShipped, @UomConvFactor, 'From Base'), @PlacesQtyUnit)
         set @CoShipPriceConv = round(dbo.UomConvAmt(@CoShipPrice, @UomConvFactor, 'From Base'), @CurrencyPlacesCp)
      end

      SET @DoHdrDoValue = Round(@DoHdrDoValue + (@CoShipPriceConv * @CoShipQtyShippedConv), @CurrencyPlaces)

      update do_hdr
      set
       do_value = @DoHdrDoValue
      where RowPointer = @DoHdrRowPointer
   end
end
else
BEGIN
   IF ((@SReturn <> 0 and @SQty > 0) or (@SReturn = 0 and @SQty < 0))
   BEGIN
      IF @SReturn <> 0
         SELECT @TAdjQty = SUM(IsNull(co_ship.qty_invoiced,0) - isnull(co_ship.qty_returned, 0))
            FROM co_ship WHERE
            co_ship.co_num = @CoitemCoNum and
            co_ship.co_line = @CoitemCoLine and
            co_ship.co_release = @CoitemCoRelease and
            isnull(co_ship.do_num, NCHAR(1)) = isnull(@SDoNum, NCHAR(1)) and
            co_ship.do_line = @SDoLine and
            ISNULL(co_ship.shipment_id, dbo.LowInt()) = ISNULL(@ShipmentId, dbo.LowInt())
      else
      BEGIN
         IF @CoShipmentApprovalRequired = 0
         BEGIN
            SELECT @TAdjQty = SUM(isnull(co_ship.qty_shipped, 0) + isnull(co_ship.qty_returned, 0) - isnull(co_ship.qty_invoiced, 0))
            FROM co_ship WHERE
            co_ship.co_num = @CoitemCoNum and
            co_ship.co_line = @CoitemCoLine and
            co_ship.co_release = @CoitemCoRelease and
            isnull(co_ship.do_num, '') = isnull(@SDoNum, '') and
            ISNULL(co_ship.do_line,'') = ISNULL(@SDoLine,'') and
            isnull(co_ship.pack_num, 0) = isnull(case when @CustomerPrintPackInv = 1 then @PackNum else co_ship.pack_num end, 0) and
            ISNULL(co_ship.shipment_id, dbo.LowInt()) = ISNULL(@ShipmentId, dbo.LowInt())
            and co_ship.qty_shipped > 0
         END
         ELSE
         BEGIN
            SELECT
               @TAdjQty = SUM(isnull(co_ship.qty_shipped, 0) + isnull(co_ship.qty_returned, 0)) -
                ISNULL((SELECT SUM(ISNULL(co_ship_approval_log.qty_approved,0))
                FROM co_ship_approval_log
                WHERE
                     co_ship.co_num      = co_ship_approval_log.co_num
                 AND co_ship.co_line     = co_ship_approval_log.co_line
                 AND co_ship.co_release  = co_ship_approval_log.co_release), 0)
            FROM co_ship
            WHERE
                 co_ship.co_num = @CoitemCoNum AND
                 co_ship.co_line = @CoitemCoLine AND
                 co_ship.co_release = @CoitemCoRelease AND
                 ISNULL(co_ship.do_num, '') = ISNULL(@SDoNum, '') AND
                 ISNULL(co_ship.do_line,'') = ISNULL(@SDoLine,'') AND
                 ISNULL(co_ship.pack_num, 0) = ISNULL(case when @CustomerPrintPackInv = 1 THEN @PackNum ELSE co_ship.pack_num END, 0) AND
                 ISNULL(co_ship.shipment_id, dbo.LowInt()) = ISNULL(@ShipmentId, dbo.LowInt())
                 AND co_ship.qty_shipped > 0
            GROUP BY co_ship.co_num,
                     co_ship.co_line,
                     co_ship.co_release
         END
      END
      IF abs(@SQty) > isnull(@TAdjQty, 0)
      BEGIN
         EXEC @Severity = dbo.MsgAppSp @Infobar OUTPUT, 'E=IsCompare>3Or1'
            , '@co_ship.qty_returned'
            , @TAdjQty
            , '@co_ship'
            , '@co_ship.do_num'
            , @SDoNum
            , '@co_ship.do_line'
            , @SDoLine
            , '@pck_hdr.pack_num'
            , @PackNum
            , '@co_ship.shipment_id'
            , @ShipmentId
         GOTO EOF
      end
   end

   SET @TAdjQty = @SQty
   SET @CoShipRowPointer = NULL

   if @ItemCostMethod = 'F'
   begin
      select top 1
       @CoShipRowPointer = co_ship.RowPointer
      ,@CoShipDateSeq = co_ship.date_seq
      ,@CoShipDoNum = co_ship.do_num
      ,@CoShipDoLine = co_ship.do_line
      ,@CoShipDoSeq = co_ship.do_seq
      ,@CoShipQtyInvoiced = co_ship.qty_invoiced
      ,@CoShipQtyReturned = co_ship.qty_returned
      ,@CoShipLbrCost = co_ship.lbr_cost
      ,@CoShipMatlCost = co_ship.matl_cost
      ,@CoShipFovhdCost = co_ship.fovhd_cost
      ,@CoShipVovhdCost = co_ship.vovhd_cost
      ,@CoShipOutCost = co_ship.out_cost
      ,@CoShipCost = co_ship.cost
      ,@CoShipCoNum = co_ship.co_num
      ,@CoShipCoLine = co_ship.co_line
      ,@CoShipCoRelease = co_ship.co_release
      ,@CoShipShipDate = co_ship.ship_date
      ,@CoShipQtyShipped = co_ship.qty_shipped
      ,@CoShipPrice = co_ship.price
      ,@CoShipUnitWeight = co_ship.unit_weight
      ,@CoShipByCons = co_ship.by_cons
      ,@CoShipShipmentId = co_ship.shipment_id
      from co_ship WITH (UPDLOCK)
      where co_ship.co_num = @CoitemCoNum and
         co_ship.co_line = @CoitemCoLine and
         co_ship.co_release = @CoitemCoRelease and
         isnull(co_ship.do_num, NCHAR(1)) = isnull(@SDoNum, NCHAR(1)) and
         co_ship.do_line = @SDoLine and
         isnull(co_ship.pack_num, 0) = isnull(case when (@SReturn = 1 and @SQty > 0) or @CustomerPrintPackInv = 0 then co_ship.pack_num else @PackNum end, 0) and
         ISNULL(co_ship.shipment_id, dbo.LowInt()) = ISNULL(@ShipmentId, dbo.LowInt())
      order by co_ship.ship_date asc, co_ship.date_seq asc
      if @@rowcount <> 1
         set @CoShipRowPointer = null
   end
   else
   begin
      -- Find the unique do_seq from co_ship or matltrack to only UPDLOCK the one co_ship record.
      SET @CoShipDoSeq = NULL
      IF NOT EXISTS (SELECT top 1 ref_num from matltrack WHERE ref_num = @SCoNum)
      BEGIN
         SELECT top 1
               @CoShipDoSeq = co_ship.do_seq
               FROM co_ship
               WHERE co_ship.co_num = @CoitemCoNum and
                     co_ship.co_line = @CoitemCoLine and
                     co_ship.co_release = @CoitemCoRelease  and
                     isnull(co_ship.do_num, NCHAR(1)) = isnull(@SDoNum, NCHAR(1)) and
                     co_ship.do_line = @SDoLine and
                     isnull(co_ship.pack_num, 0) = isnull(case when (@SReturn = 1 and @SQty > 0) or @CustomerPrintPackInv = 0 then co_ship.pack_num else @PackNum end, 0)
               order by co_ship.ship_date desc, co_ship.date_seq desc
      END
      ELSE
      BEGIN
         SELECT Top 1
           @CoShipDoSeq = do_seq.do_seq
         FROM do_seq
            left outer join matltrack with (readuncommitted) ON
               matltrack.ref_num = do_seq.ref_num
               and matltrack.ref_line_suf = do_seq.ref_line
               and matltrack.ref_release = do_seq.ref_release
               and matltrack.ref_type = 'O'
               and matltrack.trans_date = do_seq.ship_date
               and matltrack.date_seq = do_seq.date_seq
               and matltrack.qty < 0
               and isnull(matltrack.lot, '') = isnull(@SLot, '')
         WHERE do_seq.ref_num = @SCoNum
         and do_seq.ref_line = @SCoLine
         and do_seq.ref_release = @SCoRel
         and isnull(do_seq.do_num, NCHAR(1)) = isnull(@SDoNum, NCHAR(1))
         and do_seq.do_line = @SDoLine
         ORDER BY matltrack.trans_date desc, matltrack.date_seq desc
      END

      select top 1
       @CoShipRowPointer = co_ship.RowPointer
      ,@CoShipDateSeq = co_ship.date_seq
      ,@CoShipDoNum = co_ship.do_num
      ,@CoShipDoLine = co_ship.do_line
      ,@CoShipQtyInvoiced = co_ship.qty_invoiced
      ,@CoShipQtyReturned = co_ship.qty_returned
      ,@CoShipLbrCost = co_ship.lbr_cost
      ,@CoShipMatlCost = co_ship.matl_cost
      ,@CoShipFovhdCost = co_ship.fovhd_cost
      ,@CoShipVovhdCost = co_ship.vovhd_cost
      ,@CoShipOutCost = co_ship.out_cost
      ,@CoShipCost = co_ship.cost
      ,@CoShipCoNum = co_ship.co_num
      ,@CoShipCoLine = co_ship.co_line
      ,@CoShipCoRelease = co_ship.co_release
      ,@CoShipShipDate = co_ship.ship_date
      ,@CoShipQtyShipped = co_ship.qty_shipped
      ,@CoShipPrice = co_ship.price
      ,@CoShipUnitWeight = co_ship.unit_weight
      ,@CoShipByCons = co_ship.by_cons
      ,@CoShipShipmentId = co_ship.shipment_id
      from co_ship WITH (UPDLOCK)
      where co_ship.co_num = @CoitemCoNum and 
         co_ship.co_line = @CoitemCoLine and
         co_ship.co_release = @CoitemCoRelease and
         isnull(co_ship.do_num, NCHAR(1)) = isnull(@SDoNum, NCHAR(1)) and
         co_ship.do_line = @SDoLine and
         co_ship.do_seq = isnull(@CoShipDoSeq, 0) and
         isnull(co_ship.pack_num, 0) = isnull(case when (@SReturn = 1 and @SQty > 0) or @CustomerPrintPackInv = 0 then co_ship.pack_num else @PackNum end, 0) and
         ISNULL(co_ship.shipment_id, dbo.LowInt()) = ISNULL(@ShipmentId, dbo.LowInt())
         and 1 = case when @SLot is null then 1 else
            case when exists (select 1 from matltrack with (readuncommitted) where
            matltrack.ref_num = co_ship.co_num
            and matltrack.ref_line_suf = co_ship.co_line
            and matltrack.ref_release = co_ship.co_release
            and matltrack.ref_type = 'O'
            and matltrack.trans_date = co_ship.ship_date
            and matltrack.date_seq = co_ship.date_seq
            and matltrack.qty < 0
            and matltrack.lot = @SLot) then 1 else 0 end
            end
      order by co_ship.ship_date desc, co_ship.date_seq desc
         
      if @@rowcount <> 1
         set @CoShipRowPointer = null
         
      if @CoShipRowPointer is null  
      begin
         select top 1
          @CoShipRowPointer = co_ship.RowPointer
         ,@CoShipDateSeq = co_ship.date_seq
         ,@CoShipDoNum = co_ship.do_num
         ,@CoShipDoLine = co_ship.do_line
         ,@CoShipQtyInvoiced = co_ship.qty_invoiced
         ,@CoShipQtyReturned = co_ship.qty_returned
         ,@CoShipLbrCost = co_ship.lbr_cost
         ,@CoShipMatlCost = co_ship.matl_cost
         ,@CoShipFovhdCost = co_ship.fovhd_cost
         ,@CoShipVovhdCost = co_ship.vovhd_cost
         ,@CoShipOutCost = co_ship.out_cost
         ,@CoShipCost = co_ship.cost
         ,@CoShipCoNum = co_ship.co_num
         ,@CoShipCoLine = co_ship.co_line
         ,@CoShipCoRelease = co_ship.co_release
         ,@CoShipShipDate = co_ship.ship_date
         ,@CoShipQtyShipped = co_ship.qty_shipped
         ,@CoShipPrice = co_ship.price
         ,@CoShipUnitWeight = co_ship.unit_weight
         ,@CoShipByCons = co_ship.by_cons
         ,@CoShipShipmentId = co_ship.shipment_id
         from co_ship WITH (UPDLOCK)
         where co_ship.co_num = @CoitemCoNum and 
            co_ship.co_line = @CoitemCoLine and
            co_ship.co_release = @CoitemCoRelease and
            isnull(co_ship.do_num, NCHAR(1)) = isnull(@SDoNum, NCHAR(1)) and
            co_ship.do_line = @SDoLine and
            co_ship.do_seq = isnull(@CoShipDoSeq, 0) and
            isnull(co_ship.pack_num, 0) = isnull(case when (@SReturn = 1 and @SQty > 0) or @CustomerPrintPackInv = 0 then co_ship.pack_num else @PackNum end, 0) and
            ISNULL(co_ship.shipment_id, dbo.LowInt()) = ISNULL(@ShipmentId, dbo.LowInt())
         order by co_ship.ship_date desc, co_ship.date_seq desc      
         
         if @@rowcount <> 1
            set @CoShipRowPointer = null
      END   
   end

   -- Keep outside of WHILE, cause it adjusts @TAdjQty
   IF @SReturn = 0 AND @CoShipRowPointer is not null
   BEGIN
      UPDATE pckitem
      SET qty_packed = qty_packed + @TAdjQty
      WHERE pckitem.pack_num = @PackNum
        AND pckitem.co_line = @CoShipCoLine
        AND pckitem.co_release = @CoShipCoRelease   
   END

   WHILE (@CoShipRowPointer is not null)
   BEGIN
      SET @TDateSeq = @CoShipDateSeq

      IF @SReturn <> 0
      BEGIN
         if @CoShipQtyInvoiced > 0
         begin
            SET @CoShipQtyReturned = @CoShipQtyReturned + @TAdjQty
            SET @CoShipQtyShipped = @CoShipQtyShipped - @TAdjQty
            SET @CoShipOrigInvoice = @SOrigInvoice
            SET @CoShipReasonText = @SReasonText

            update co_ship
            set
             qty_returned = @CoShipQtyReturned
            ,qty_shipped = @CoShipQtyShipped
            ,orig_inv_num = @CoShipOrigInvoice
            ,reason_text  = @CoShipReasonText
            where RowPointer = @CoShipRowPointer

            SET @CoitemConsNum = @CoitemConsNum -
               CASE WHEN @CoShipByCons <> 0 and @CoShipQtyShipped <= 0
               then 1
               else 0 END

            if @CoShipQtyShipped < 0
            BEGIN
               SET @TAdjQty = - @CoShipQtyShipped
               SET @CoShipQtyReturned = @CoShipQtyReturned - @TAdjQty
               SET @CoShipQtyShipped = 0

               update co_ship
               set
                qty_returned = @CoShipQtyReturned
               ,qty_shipped = @CoShipQtyShipped
               where RowPointer = @CoShipRowPointer
            END
            else
               BREAK
         end
      end
      else
      BEGIN
         /* s-qty < 0 */

         SET @CoShipQtyShipped = @CoShipQtyShipped + @TAdjQty

         SET @CoitemConsNum = @CoitemConsNum -
            CASE WHEN @CoShipByCons <> 0 and @CoShipQtyShipped <= 0
            then 1
            else 0 END
         SET @TAdjQty = 0
       
         IF @CoShipmentApprovalRequired = 1 
         BEGIN
            SELECT @CoShipQtyApproved = SUM(ISNULL(co_ship_approval_log.qty_approved, 0))
              FROM co_ship_approval_log
              JOIN co_ship ON co_ship.co_num = co_ship_approval_log.co_num
               AND co_ship.co_line     = co_ship_approval_log.co_line
               AND co_ship.co_release  = co_ship_approval_log.co_release
               AND co_ship.date_seq    = co_ship_approval_log.date_seq
             WHERE co_ship.RowPointer  = @CoShipRowPointer

            IF @CoShipQtyShipped + @CoShipQtyReturned < @CoShipQtyApproved
            BEGIN
               SET @TAdjQty = @CoShipQtyReturned + @CoShipQtyShipped - @CoShipQtyApproved

               SET @CoShipQtyShipped = @CoShipQtyShipped - @TAdjQty
            END
         END
         ELSE
         BEGIN
            IF @CoShipQtyShipped + @CoShipQtyReturned < @CoShipQtyInvoiced
            BEGIN
               SET @TAdjQty = @CoShipQtyReturned + @CoShipQtyShipped - @CoShipQtyInvoiced

               SET @CoShipQtyShipped = @CoShipQtyShipped - @TAdjQty
            END
         END
         SET @CoShipOrigInvoice = @SOrigInvoice
         SET @CoShipReasonText = @SReasonText

         update co_ship
         set
           qty_shipped = @CoShipQtyShipped
          ,orig_inv_num = @CoShipOrigInvoice
          ,reason_text = @CoShipReasonText
         where RowPointer = @CoShipRowPointer

         if @CoShipQtyShipped + @CoShipQtyReturned = 0
         BEGIN
            if @SDoNum IS NOT NULL
               delete do_seq
                  where do_num = @CoShipDoNum
                  and do_line  = @CoShipDoLine
                  and do_seq   = @CoShipDoSeq

            delete co_ship where co_ship.RowPointer = @CoShipRowPointer
            set @CoShipRowPointer = null
         end

         update con_inv_item
            set con_inv_item.regen = 1
            where con_inv_item.co_num = @CoShipCoNum
            and con_inv_item.co_line = @CoShipCoLine
            and con_inv_item.co_release = @CoShipCoRelease
            and con_inv_item.regen = 0

         if @TAdjQty = 0
            BREAK
      end

      if @ItemCostMethod = 'F'
      BEGIN
         if (@CoShipRowPointer is not null)
         begin
            select top 1
             @CoShipRowPointer = co_ship.RowPointer
            ,@CoShipDateSeq = co_ship.date_seq
            ,@CoShipDoNum = co_ship.do_num
            ,@CoShipDoLine = co_ship.do_line
            ,@CoShipDoSeq = co_ship.do_seq
            ,@CoShipQtyInvoiced = co_ship.qty_invoiced
            ,@CoShipQtyReturned = co_ship.qty_returned
            ,@CoShipLbrCost = co_ship.lbr_cost
            ,@CoShipMatlCost = co_ship.matl_cost
            ,@CoShipFovhdCost = co_ship.fovhd_cost
            ,@CoShipVovhdCost = co_ship.vovhd_cost
            ,@CoShipOutCost = co_ship.out_cost
            ,@CoShipCost = co_ship.cost
            ,@CoShipCoNum = co_ship.co_num
            ,@CoShipCoLine = co_ship.co_line
            ,@CoShipCoRelease = co_ship.co_release
            ,@CoShipShipDate = co_ship.ship_date
            ,@CoShipQtyShipped = co_ship.qty_shipped
            ,@CoShipPrice = co_ship.price
            ,@CoShipUnitWeight = co_ship.unit_weight
            ,@CoShipByCons = co_ship.by_cons
            ,@CoShipShipmentId = co_ship.shipment_id
            from co_ship WITH (UPDLOCK)
            where ( co_ship.co_num = @CoitemCoNum and
               co_ship.co_line = @CoitemCoLine and
               co_ship.co_release = @CoitemCoRelease and
               isnull(co_ship.do_num, NCHAR(1)) = isnull(@SDoNum, NCHAR(1)) and
               co_ship.do_line = @SDoLine
              ) and ((co_ship.ship_date = @CoShipShipDate and co_ship.date_seq = @CoShipDateSeq and co_ship.RowPointer > @CoShipRowPointer) or (co_ship.ship_date = @CoShipShipDate and co_ship.date_seq > @CoShipDateSeq) or (co_ship.ship_date > @CoShipShipDate))
               and isnull(co_ship.pack_num, 0) = isnull(case when (@SReturn = 1 and @SQty > 0) or @CustomerPrintPackInv = 0 then co_ship.pack_num else @PackNum end, 0)
               and ISNULL(co_ship.shipment_id, dbo.LowInt()) = ISNULL(@ShipmentId, dbo.LowInt())
            order by co_ship.ship_date asc, co_ship.date_seq asc
            if @@rowcount <> 1
               set @CoShipRowPointer = null
         end
         else
         begin
            select top 1
             @CoShipRowPointer = co_ship.RowPointer
            ,@CoShipDateSeq = co_ship.date_seq
            ,@CoShipDoNum = co_ship.do_num
            ,@CoShipDoLine = co_ship.do_line
            ,@CoShipDoSeq = co_ship.do_seq
            ,@CoShipQtyInvoiced = co_ship.qty_invoiced
            ,@CoShipQtyReturned = co_ship.qty_returned
            ,@CoShipLbrCost = co_ship.lbr_cost
            ,@CoShipMatlCost = co_ship.matl_cost
            ,@CoShipFovhdCost = co_ship.fovhd_cost
            ,@CoShipVovhdCost = co_ship.vovhd_cost
            ,@CoShipOutCost = co_ship.out_cost
            ,@CoShipCost = co_ship.cost
            ,@CoShipCoNum = co_ship.co_num
            ,@CoShipCoLine = co_ship.co_line
            ,@CoShipCoRelease = co_ship.co_release
            ,@CoShipShipDate = co_ship.ship_date
            ,@CoShipQtyShipped = co_ship.qty_shipped
            ,@CoShipPrice = co_ship.price
            ,@CoShipUnitWeight = co_ship.unit_weight
            ,@CoShipByCons = co_ship.by_cons
            ,@CoShipShipmentId = co_ship.shipment_id
            from co_ship WITH (UPDLOCK)
            where co_ship.co_num = @CoitemCoNum and
               co_ship.co_line = @CoitemCoLine and
               co_ship.co_release = @CoitemCoRelease and
               isnull(co_ship.do_num, NCHAR(1)) = isnull(@SDoNum, NCHAR(1)) and
               co_ship.do_line = @SDoLine
               and isnull(co_ship.pack_num, 0) = isnull(case when (@SReturn = 1 and @SQty > 0) or @CustomerPrintPackInv = 0 then co_ship.pack_num else @PackNum end, 0)
               and ISNULL(co_ship.shipment_id, dbo.LowInt()) = ISNULL(@ShipmentId, dbo.LowInt())
            order by co_ship.ship_date asc, co_ship.date_seq asc
            if @@rowcount <> 1
               set @CoShipRowPointer = null
         end
      end
      else
      BEGIN
         if (@CoShipRowPointer is not null)
         begin
            select top 1
             @CoShipRowPointer = co_ship.RowPointer
            ,@CoShipDateSeq = co_ship.date_seq
            ,@CoShipDoNum = co_ship.do_num
            ,@CoShipDoLine = co_ship.do_line
            ,@CoShipDoSeq = co_ship.do_seq
            ,@CoShipQtyInvoiced = co_ship.qty_invoiced
            ,@CoShipQtyReturned = co_ship.qty_returned
            ,@CoShipLbrCost = co_ship.lbr_cost
            ,@CoShipMatlCost = co_ship.matl_cost
            ,@CoShipFovhdCost = co_ship.fovhd_cost
            ,@CoShipVovhdCost = co_ship.vovhd_cost
            ,@CoShipOutCost = co_ship.out_cost
            ,@CoShipCost = co_ship.cost
            ,@CoShipCoNum = co_ship.co_num
            ,@CoShipCoLine = co_ship.co_line
            ,@CoShipCoRelease = co_ship.co_release
            ,@CoShipShipDate = co_ship.ship_date
            ,@CoShipQtyShipped = co_ship.qty_shipped
            ,@CoShipPrice = co_ship.price
            ,@CoShipUnitWeight = co_ship.unit_weight
            ,@CoShipByCons = co_ship.by_cons
            ,@CoShipShipmentId = co_ship.shipment_id
            from co_ship WITH (UPDLOCK)
            where ( co_ship.co_num = @CoitemCoNum and
               co_ship.co_line = @CoitemCoLine and
               co_ship.co_release = @CoitemCoRelease and
               isnull(co_ship.do_num, NCHAR(1)) = isnull(@SDoNum, NCHAR(1)) and
               co_ship.do_line = @SDoLine
              ) and ((co_ship.ship_date = @CoShipShipDate and co_ship.date_seq = @CoShipDateSeq and co_ship.RowPointer < @CoShipRowPointer) or (co_ship.ship_date = @CoShipShipDate and co_ship.date_seq < @CoShipDateSeq) or (co_ship.ship_date < @CoShipShipDate))
               and isnull(co_ship.pack_num, 0) = isnull(case when (@SReturn = 1 and @SQty > 0) or @CustomerPrintPackInv = 0 then co_ship.pack_num else @PackNum end, 0)
               and ISNULL(co_ship.shipment_id, dbo.LowInt()) = ISNULL(@ShipmentId, dbo.LowInt())
               and 1 = case when @SLot is null then 1 else
                  case when exists (select 1 from matltrack with (readuncommitted) where
                  matltrack.ref_num = co_ship.co_num
                  and matltrack.ref_line_suf = co_ship.co_line
                  and matltrack.ref_release = co_ship.co_release
                  and matltrack.ref_type = 'O'
                  and matltrack.trans_date = co_ship.ship_date
                  and matltrack.date_seq = co_ship.date_seq
                  and matltrack.qty < 0
                  and matltrack.lot = @SLot) then 1 else 0 end
                  end
            order by co_ship.ship_date desc, co_ship.date_seq desc

            if @@rowcount <> 1
               set @CoShipRowPointer = null            

            if @CoShipRowPointer is null
            begin
               select top 1
                @CoShipRowPointer = co_ship.RowPointer
               ,@CoShipDateSeq = co_ship.date_seq
               ,@CoShipDoNum = co_ship.do_num
               ,@CoShipDoLine = co_ship.do_line
               ,@CoShipDoSeq = co_ship.do_seq
               ,@CoShipQtyInvoiced = co_ship.qty_invoiced
               ,@CoShipQtyReturned = co_ship.qty_returned
               ,@CoShipLbrCost = co_ship.lbr_cost
               ,@CoShipMatlCost = co_ship.matl_cost
               ,@CoShipFovhdCost = co_ship.fovhd_cost
               ,@CoShipVovhdCost = co_ship.vovhd_cost
               ,@CoShipOutCost = co_ship.out_cost
               ,@CoShipCost = co_ship.cost
               ,@CoShipCoNum = co_ship.co_num
               ,@CoShipCoLine = co_ship.co_line
               ,@CoShipCoRelease = co_ship.co_release
               ,@CoShipShipDate = co_ship.ship_date
               ,@CoShipQtyShipped = co_ship.qty_shipped
               ,@CoShipPrice = co_ship.price
               ,@CoShipUnitWeight = co_ship.unit_weight
               ,@CoShipByCons = co_ship.by_cons
               ,@CoShipShipmentId = co_ship.shipment_id
               from co_ship WITH (UPDLOCK)
               where ( co_ship.co_num = @CoitemCoNum and
                  co_ship.co_line = @CoitemCoLine and
                  co_ship.co_release = @CoitemCoRelease and
                  isnull(co_ship.do_num, NCHAR(1)) = isnull(@SDoNum, NCHAR(1)) and
                  co_ship.do_line = @SDoLine
                  ) and ((co_ship.ship_date = @CoShipShipDate and co_ship.date_seq = @CoShipDateSeq and co_ship.RowPointer < @CoShipRowPointer) or (co_ship.ship_date = @CoShipShipDate and co_ship.date_seq < @CoShipDateSeq) or (co_ship.ship_date < @CoShipShipDate))
                  and isnull(co_ship.pack_num, 0) = isnull(case when (@SReturn = 1 and @SQty > 0) or @CustomerPrintPackInv = 0 then co_ship.pack_num else @PackNum end, 0)
                  and ISNULL(co_ship.shipment_id, dbo.LowInt()) = ISNULL(@ShipmentId, dbo.LowInt())
               order by co_ship.ship_date desc, co_ship.date_seq desc            
            
               if @@rowcount <> 1
                  set @CoShipRowPointer = null
            end   
         end
         else
         begin
            select top 1
             @CoShipRowPointer = co_ship.RowPointer
            ,@CoShipDateSeq = co_ship.date_seq
            ,@CoShipDoNum = co_ship.do_num
            ,@CoShipDoLine = co_ship.do_line
            ,@CoShipDoSeq = co_ship.do_seq
            ,@CoShipQtyInvoiced = co_ship.qty_invoiced
            ,@CoShipQtyReturned = co_ship.qty_returned
            ,@CoShipLbrCost = co_ship.lbr_cost
            ,@CoShipMatlCost = co_ship.matl_cost
            ,@CoShipFovhdCost = co_ship.fovhd_cost
            ,@CoShipVovhdCost = co_ship.vovhd_cost
            ,@CoShipOutCost = co_ship.out_cost
            ,@CoShipCost = co_ship.cost
            ,@CoShipCoNum = co_ship.co_num
            ,@CoShipCoLine = co_ship.co_line
            ,@CoShipCoRelease = co_ship.co_release
            ,@CoShipShipDate = co_ship.ship_date
            ,@CoShipQtyShipped = co_ship.qty_shipped
            ,@CoShipPrice = co_ship.price
            ,@CoShipUnitWeight = co_ship.unit_weight
            ,@CoShipByCons = co_ship.by_cons
            ,@CoShipShipmentId = co_ship.shipment_id
            from co_ship WITH (UPDLOCK)
            where co_ship.co_num = @CoitemCoNum and
               co_ship.co_line = @CoitemCoLine and
               co_ship.co_release = @CoitemCoRelease and
               isnull(co_ship.do_num, NCHAR(1)) = isnull(@SDoNum, NCHAR(1)) and
               co_ship.do_line = @SDoLine
               and isnull(co_ship.pack_num, 0) = isnull(case when (@SReturn = 1 and @SQty > 0) or @CustomerPrintPackInv = 0 then co_ship.pack_num else @PackNum end, 0)
               and ISNULL(co_ship.shipment_id, dbo.LowInt()) = ISNULL(@ShipmentId, dbo.LowInt())
               and 1 = case when @SLot is null then 1 else
                  case when exists (select 1 from matltrack with (readuncommitted) where
                  matltrack.ref_num = co_ship.co_num
                  and matltrack.ref_line_suf = co_ship.co_line
                  and matltrack.ref_release = co_ship.co_release
                  and matltrack.ref_type = 'O'
                  and matltrack.trans_date = co_ship.ship_date
                  and matltrack.date_seq = co_ship.date_seq
                  and matltrack.qty < 0
                  and matltrack.lot = @SLot) then 1 else 0 end
                  end
            order by co_ship.ship_date desc, co_ship.date_seq desc

            if @@rowcount <> 1
               set @CoShipRowPointer = null

            if @CoShipRowPointer is null
            begin
               select top 1
                @CoShipRowPointer = co_ship.RowPointer
               ,@CoShipDateSeq = co_ship.date_seq
               ,@CoShipDoNum = co_ship.do_num
               ,@CoShipDoLine = co_ship.do_line
               ,@CoShipDoSeq = co_ship.do_seq
               ,@CoShipQtyInvoiced = co_ship.qty_invoiced
               ,@CoShipQtyReturned = co_ship.qty_returned
               ,@CoShipLbrCost = co_ship.lbr_cost
               ,@CoShipMatlCost = co_ship.matl_cost
               ,@CoShipFovhdCost = co_ship.fovhd_cost
               ,@CoShipVovhdCost = co_ship.vovhd_cost
               ,@CoShipOutCost = co_ship.out_cost
               ,@CoShipCost = co_ship.cost
               ,@CoShipCoNum = co_ship.co_num
               ,@CoShipCoLine = co_ship.co_line
               ,@CoShipCoRelease = co_ship.co_release
               ,@CoShipShipDate = co_ship.ship_date
               ,@CoShipQtyShipped = co_ship.qty_shipped
               ,@CoShipPrice = co_ship.price
               ,@CoShipUnitWeight = co_ship.unit_weight
               ,@CoShipByCons = co_ship.by_cons
               ,@CoShipShipmentId = co_ship.shipment_id
               from co_ship WITH (UPDLOCK)
               where co_ship.co_num = @CoitemCoNum and
                  co_ship.co_line = @CoitemCoLine and
                  co_ship.co_release = @CoitemCoRelease and
                  isnull(co_ship.do_num, NCHAR(1)) = isnull(@SDoNum, NCHAR(1)) and
                  co_ship.do_line = @SDoLine
                  and isnull(co_ship.pack_num, 0) = isnull(case when (@SReturn = 1 and @SQty > 0) or @CustomerPrintPackInv = 0 then co_ship.pack_num else @PackNum end, 0)
                  and ISNULL(co_ship.shipment_id, dbo.LowInt()) = ISNULL(@ShipmentId, dbo.LowInt())
               order by co_ship.ship_date desc, co_ship.date_seq desc
            
               if @@rowcount <> 1
                  set @CoShipRowPointer = null
            end   
         end
      end
   end
end

/* IF ITEM IS RETURNED, BUT NOT TO STOCK, DON'T POST A */
/* MATL-TRAN FOR ITEM OR UPDATE LIFO, BUT UPDATE COITEM */
IF @SReturn <> 0 AND @SRetToStock = 0
BEGIN
   UPDATE itemcust
      SET itemcust.ship_ytd = itemcust.ship_ytd - @SQty
      where itemcust.cust_num = @CoCustNum
      and itemcust.item = @CoitemItem
      and isnull(itemcust.cust_item, nchar(1)) = isnull(@CoitemCustItem, nchar(1))

   IF @CoitemQtyShipped < @SQty
   BEGIN
      BEGIN
         SET @MsgParm2 = dbo.UomConvQty(@CoitemQtyShipped, @UomConvFactor, 'From Base')

         EXEC @MsgSeverity = dbo.MsgAppSp @Infobar OUTPUT, 'E=NoCompare>'
            , '@coitem.qty_shipped', @MsgParm2
         IF @MsgSeverity >= ISNULL(@Severity, 0)
            SET @Severity = @MsgSeverity
      END

      GOTO EOF
   end

    /* REDUCE OUTSTANDING CGS BY AVG. VALUE RETURNED/DISCARDED */
   SET @CoitemCgsTotalLbr   = @CoitemCgsTotalLbr   - round(@SQty * @AvgLbrCost  , @TDomPlaces)
   SET @CoitemCgsTotalMatl  = @CoitemCgsTotalMatl  - round(@SQty * @AvgMatlCost , @TDomPlaces)
   SET @CoitemCgsTotalFovhd = @CoitemCgsTotalFovhd - round(@SQty * @AvgFovhdCost, @TDomPlaces)
   SET @CoitemCgsTotalVovhd = @CoitemCgsTotalVovhd - round(@SQty * @AvgVovhdCost, @TDomPlaces)
   SET @CoitemCgsTotalOut   = @CoitemCgsTotalOut   - round(@SQty * @AvgOutCost  , @TDomPlaces)

   SET @CoitemCgsTotal = @CoitemCgsTotalLbr + @CoitemCgsTotalMatl + @CoitemCgsTotalFovhd + @CoitemCgsTotalVovhd + @CoitemCgsTotalOut

   SET @CoitemQtyShipped = @CoitemQtyShipped - @SQty

   SET @TOrderBal = - dbo.LineBalSp (
        @CoitemQtyOrdered
      , @CoitemQtyInvoiced
      , @CoitemQtyReturned
      , @CoitemPrice
      , @CoitemDisc
      , @CoitemPrgBillTot
      , @CoitemPrgBillApp
      , @TPlaces
      )
   SET @CoitemQtyReturned = @CoitemQtyReturned + @SQty

   SET @TOrderBal = @TOrderBal + dbo.LineBalSp (
        @CoitemQtyOrdered
      , @CoitemQtyInvoiced
      , @CoitemQtyReturned
      , @CoitemPrice
      , @CoitemDisc
      , @CoitemPrgBillTot
      , @CoitemPrgBillApp
      , @TPlaces
      )

   if @TOrderBal <> 0.0
      EXEC dbo.CredChkSp
           @CustNum     = @CoCustNum
         , @Adjust      = @TOrderBal
         , @CoNum       = @CoCoNum
         , @OrigSite    = @CoOrigSite
         , @Infobar     = @Infobar OUTPUT

   /* if a return, but not to stock, trx is processed, the qty packed
    * should be reduced so that the return can be packed again later */
   IF @CoitemQtyPacked > 0
   BEGIN
      IF @CoitemQtyPacked <> @CoitemQtyOrdered
      BEGIN
         EXEC @MsgSeverity = dbo.MsgAppSp @Infobar OUTPUT, 'COShippingTrxPostSpQtyToPackWarning'

         IF @MsgSeverity >= ISNULL(@Severity, 0)
            SET @Severity = @MsgSeverity
      END

      SET @CoitemQtyPacked = dbo.MaxQty(0, @CoitemQtyPacked - @TAdjQty)
   END

   IF @NonInventoryItem <> 1
   BEGIN
      If @CoitemRefType = 'I' or (@CoitemRefType <> 'I' and @CoitemRefNum is not null)
      BEGIN
      SET @CoitemQtyReady =
         CASE WHEN @CoitemQtyRsvd > 0
            THEN @CoitemQtyRsvd
            else dbo.MinQtySp(
               @CoitemQtyOrdered,
               dbo.MinQtySp(
                  dbo.MaxQtySp(0.0,
                     @CoitemQtyReady +
                     CASE WHEN @CoitemQtyShipped <= @CoitemQtyOrdered
                        then dbo.MinQtySp(@SQty, @CoitemQtyOrdered - @CoitemQtyShipped)
                        else dbo.MinQtySp(@CoitemQtyShipped + @SQty - @CoitemQtyOrdered, 0.0)
                     END
                     )
                  ,
                  dbo.MaxQtySp(0.0,@ItemwhseQtyOnHand - @ItemwhseQtyRsvdCo)
                  )
               )
         END
      END
   END
   ELSE
      SET @CoitemQtyReady = dbo.MaxQty(0, dbo.MinQtySp(@SQty, @CoitemQtyOrdered - @CoitemQtyShipped))

   select top 1
    @XCoShipRowPointer = x_co_ship.RowPointer
   ,@XCoShipShipDate = x_co_ship.ship_date
   from co_ship  as x_co_ship
   where x_co_ship.co_num = @CoitemCoNum
      AND x_co_ship.co_line = @CoitemCoLine
      AND x_co_ship.co_release = @CoitemCoRelease
   order by x_co_ship.ship_date desc
   if @@rowcount <> 1
      set @XCoShipRowPointer = null

   SET @CoitemShipDate = CASE WHEN (@XCoShipRowPointer is not null) then @XCoShipShipDate ELSE NULL END
   if @CoitemStat = 'F' and round(@CoitemQtyShipped - @CoitemQtyOrdered, @PlacesQtyUnit) < 0
   BEGIN
      SET @CoitemStat = 'O'
      /* If going from (F)illed to (O)rdered, the item master information
       * is updated to reflect the items that are ALLOC ORDER again.
       * We want to increase the On Order by the unshipped quantity. */
      SET @ItemwhseQtyAllocCo = @ItemwhseQtyAllocCo + @CoitemQtyOrdered - @CoitemQtyShipped
   END
   ELSE
   IF @CoitemStat = 'O'
      SET @ItemwhseQtyAllocCo = @ItemwhseQtyAllocCo + @SQty

   /* if not returning item(s) to stock, leave now */
end
ELSE
BEGIN
   IF @NonInventoryItem <> 1
   BEGIN

   IF @CoShipmentApprovalRequired = 0
   BEGIN
      select
       @ItemlocRowPointer = itemloc.RowPointer
      ,@ItemlocWhse = itemloc.whse
      ,@ItemlocItem = itemloc.item
      ,@ItemlocLoc = itemloc.loc
      ,@ItemlocMrbFlag = itemloc.mrb_flag
      ,@ItemlocLocType = itemloc.loc_type
      ,@ItemlocQtyOnHand = itemloc.qty_on_hand
      ,@ItemlocInvAcct = itemloc.inv_acct
      ,@ItemlocLbrAcct = itemloc.lbr_acct
      ,@ItemlocFovhdAcct = itemloc.fovhd_acct
      ,@ItemlocVovhdAcct = itemloc.vovhd_acct
      ,@ItemlocOutAcct = itemloc.out_acct
      ,@ItemlocInvAcctUnit1 = itemloc.inv_acct_unit1
      ,@ItemlocInvAcctUnit2 = itemloc.inv_acct_unit2
      ,@ItemlocInvAcctUnit3 = itemloc.inv_acct_unit3
      ,@ItemlocInvAcctUnit4 = itemloc.inv_acct_unit4
      ,@ItemlocLbrAcctUnit1 = itemloc.lbr_acct_unit1
      ,@ItemlocLbrAcctUnit2 = itemloc.lbr_acct_unit2
      ,@ItemlocLbrAcctUnit3 = itemloc.lbr_acct_unit3
      ,@ItemlocLbrAcctUnit4 = itemloc.lbr_acct_unit4
      ,@ItemlocFovhdAcctUnit1 = itemloc.fovhd_acct_unit1
      ,@ItemlocFovhdAcctUnit2 = itemloc.fovhd_acct_unit2
      ,@ItemlocFovhdAcctUnit3 = itemloc.fovhd_acct_unit3
      ,@ItemlocFovhdAcctUnit4 = itemloc.fovhd_acct_unit4
      ,@ItemlocVovhdAcctUnit1 = itemloc.vovhd_acct_unit1
      ,@ItemlocVovhdAcctUnit2 = itemloc.vovhd_acct_unit2
      ,@ItemlocVovhdAcctUnit3 = itemloc.vovhd_acct_unit3
      ,@ItemlocVovhdAcctUnit4 = itemloc.vovhd_acct_unit4
      ,@ItemlocOutAcctUnit1 = itemloc.out_acct_unit1
      ,@ItemlocOutAcctUnit2 = itemloc.out_acct_unit2
      ,@ItemlocOutAcctUnit3 = itemloc.out_acct_unit3
      ,@ItemlocOutAcctUnit4 = itemloc.out_acct_unit4
      ,@ItemlocLbrCost = itemloc.lbr_cost
      ,@ItemlocMatlCost = itemloc.matl_cost
      ,@ItemlocFovhdCost = itemloc.fovhd_cost
      ,@ItemlocVovhdCost = itemloc.vovhd_cost
      ,@ItemlocOutCost = itemloc.out_cost
      ,@ItemlocUnitCost = itemloc.unit_cost
      ,@ItemlocPermFlag = itemloc.perm_flag
      ,@ItemlifoItemlocInvAcct = itemloc.inv_acct
      ,@ItemlifoItemlocLbrAcct = itemloc.lbr_acct
      ,@ItemlifoItemlocFovhdAcct = itemloc.fovhd_acct
      ,@ItemlifoItemlocVovhdAcct = itemloc.vovhd_acct
      ,@ItemlifoItemlocOutAcct = itemloc.out_acct
      ,@ItemlifoItemlocInvAcctUnit1 = itemloc.inv_acct_unit1
      ,@ItemlifoItemlocInvAcctUnit2 = itemloc.inv_acct_unit2
      ,@ItemlifoItemlocInvAcctUnit3 = itemloc.inv_acct_unit3
      ,@ItemlifoItemlocInvAcctUnit4 = itemloc.inv_acct_unit4
      ,@ItemlifoItemlocLbrAcctUnit1 = itemloc.lbr_acct_unit1
      ,@ItemlifoItemlocLbrAcctUnit2 = itemloc.lbr_acct_unit2
      ,@ItemlifoItemlocLbrAcctUnit3 = itemloc.lbr_acct_unit3
      ,@ItemlifoItemlocLbrAcctUnit4 = itemloc.lbr_acct_unit4
      ,@ItemlifoItemlocFovhdAcctUnit1 = itemloc.fovhd_acct_unit1
      ,@ItemlifoItemlocFovhdAcctUnit2 = itemloc.fovhd_acct_unit2
      ,@ItemlifoItemlocFovhdAcctUnit3 = itemloc.fovhd_acct_unit3
      ,@ItemlifoItemlocFovhdAcctUnit4 = itemloc.fovhd_acct_unit4
      ,@ItemlifoItemlocVovhdAcctUnit1 = itemloc.vovhd_acct_unit1
      ,@ItemlifoItemlocVovhdAcctUnit2 = itemloc.vovhd_acct_unit2
      ,@ItemlifoItemlocVovhdAcctUnit3 = itemloc.vovhd_acct_unit3
      ,@ItemlifoItemlocVovhdAcctUnit4 = itemloc.vovhd_acct_unit4
      ,@ItemlifoItemlocOutAcctUnit1 = itemloc.out_acct_unit1
      ,@ItemlifoItemlocOutAcctUnit2 = itemloc.out_acct_unit2
      ,@ItemlifoItemlocOutAcctUnit3 = itemloc.out_acct_unit3
      ,@ItemlifoItemlocOutAcctUnit4 = itemloc.out_acct_unit4
      from itemloc WITH (UPDLOCK)
      where itemloc.whse = @CoitemWhse
        and itemloc.item = @SItem
        and itemloc.loc  = @SLoc
   END
   ELSE
   BEGIN
      select
      @ItemlocRowPointer = itemloc.RowPointer
      ,@ItemlocWhse = itemloc.whse
      ,@ItemlocItem = itemloc.item
      ,@ItemlocLoc = itemloc.loc
      ,@ItemlocMrbFlag = itemloc.mrb_flag
      ,@ItemlocLocType = itemloc.loc_type
      ,@ItemlocQtyOnHand = itemloc.qty_on_hand
      ,@ItemlocInvAcct = itemloc.inv_in_proc_acct
      ,@ItemlocLbrAcct = itemloc.lbr_in_proc_acct
      ,@ItemlocFovhdAcct = itemloc.fovhd_in_proc_acct
      ,@ItemlocVovhdAcct = itemloc.vovhd_in_proc_acct
      ,@ItemlocOutAcct = itemloc.out_in_proc_acct
      ,@ItemlocInvAcctUnit1 = itemloc.inv_in_proc_acct_unit1
      ,@ItemlocInvAcctUnit2 = itemloc.inv_in_proc_acct_unit2
      ,@ItemlocInvAcctUnit3 = itemloc.inv_in_proc_acct_unit3
      ,@ItemlocInvAcctUnit4 = itemloc.inv_in_proc_acct_unit4
      ,@ItemlocLbrAcctUnit1 = itemloc.lbr_in_proc_acct_unit1
      ,@ItemlocLbrAcctUnit2 = itemloc.lbr_in_proc_acct_unit2
      ,@ItemlocLbrAcctUnit3 = itemloc.lbr_in_proc_acct_unit3
      ,@ItemlocLbrAcctUnit4 = itemloc.lbr_in_proc_acct_unit4
      ,@ItemlocFovhdAcctUnit1 = itemloc.fovhd_in_proc_acct_unit1
      ,@ItemlocFovhdAcctUnit2 = itemloc.fovhd_in_proc_acct_unit2
      ,@ItemlocFovhdAcctUnit3 = itemloc.fovhd_in_proc_acct_unit3
      ,@ItemlocFovhdAcctUnit4 = itemloc.fovhd_in_proc_acct_unit4
      ,@ItemlocVovhdAcctUnit1 = itemloc.vovhd_in_proc_acct_unit1
      ,@ItemlocVovhdAcctUnit2 = itemloc.vovhd_in_proc_acct_unit2
      ,@ItemlocVovhdAcctUnit3 = itemloc.vovhd_in_proc_acct_unit3
      ,@ItemlocVovhdAcctUnit4 = itemloc.vovhd_in_proc_acct_unit4
      ,@ItemlocOutAcctUnit1 = itemloc.out_in_proc_acct_unit1
      ,@ItemlocOutAcctUnit2 = itemloc.out_in_proc_acct_unit2
      ,@ItemlocOutAcctUnit3 = itemloc.out_in_proc_acct_unit3
      ,@ItemlocOutAcctUnit4 = itemloc.out_in_proc_acct_unit4
      ,@ItemlocLbrCost = itemloc.lbr_cost
      ,@ItemlocMatlCost = itemloc.matl_cost
      ,@ItemlocFovhdCost = itemloc.fovhd_cost
      ,@ItemlocVovhdCost = itemloc.vovhd_cost
      ,@ItemlocOutCost = itemloc.out_cost
      ,@ItemlocUnitCost = itemloc.unit_cost
      ,@ItemlocPermFlag = itemloc.perm_flag
      ,@ItemlifoItemlocInvAcct = itemloc.inv_acct
      ,@ItemlifoItemlocLbrAcct = itemloc.lbr_acct
      ,@ItemlifoItemlocFovhdAcct = itemloc.fovhd_acct
      ,@ItemlifoItemlocVovhdAcct = itemloc.vovhd_acct
      ,@ItemlifoItemlocOutAcct = itemloc.out_acct
      ,@ItemlifoItemlocInvAcctUnit1 = itemloc.inv_acct_unit1
      ,@ItemlifoItemlocInvAcctUnit2 = itemloc.inv_acct_unit2
      ,@ItemlifoItemlocInvAcctUnit3 = itemloc.inv_acct_unit3
      ,@ItemlifoItemlocInvAcctUnit4 = itemloc.inv_acct_unit4
      ,@ItemlifoItemlocLbrAcctUnit1 = itemloc.lbr_acct_unit1
      ,@ItemlifoItemlocLbrAcctUnit2 = itemloc.lbr_acct_unit2
      ,@ItemlifoItemlocLbrAcctUnit3 = itemloc.lbr_acct_unit3
      ,@ItemlifoItemlocLbrAcctUnit4 = itemloc.lbr_acct_unit4
      ,@ItemlifoItemlocFovhdAcctUnit1 = itemloc.fovhd_acct_unit1
      ,@ItemlifoItemlocFovhdAcctUnit2 = itemloc.fovhd_acct_unit2
      ,@ItemlifoItemlocFovhdAcctUnit3 = itemloc.fovhd_acct_unit3
      ,@ItemlifoItemlocFovhdAcctUnit4 = itemloc.fovhd_acct_unit4
      ,@ItemlifoItemlocVovhdAcctUnit1 = itemloc.vovhd_acct_unit1
      ,@ItemlifoItemlocVovhdAcctUnit2 = itemloc.vovhd_acct_unit2
      ,@ItemlifoItemlocVovhdAcctUnit3 = itemloc.vovhd_acct_unit3
      ,@ItemlifoItemlocVovhdAcctUnit4 = itemloc.vovhd_acct_unit4
      ,@ItemlifoItemlocOutAcctUnit1 = itemloc.out_acct_unit1
      ,@ItemlifoItemlocOutAcctUnit2 = itemloc.out_acct_unit2
      ,@ItemlifoItemlocOutAcctUnit3 = itemloc.out_acct_unit3
      ,@ItemlifoItemlocOutAcctUnit4 = itemloc.out_acct_unit4
      from itemloc WITH (UPDLOCK)
      where itemloc.whse = @CoitemWhse
        and itemloc.item = @SItem
        and itemloc.loc  = @SLoc
   END

   if @@rowcount <> 1
      set @ItemlocRowPointer = null

   if @ItemlocRowPointer is null
   BEGIN
      /* SEE IF CAN ADD ITEMLOC */
      EXEC @Severity = dbo.ItemLocCheckSp
           @PItem   = @SItem
         , @PWhse   = @CoitemWhse
         , @PLoc    = @SLoc
         , @Infobar = @Infobar OUTPUT
      , @CreateIfMissing = 1
      , @ItemlocRowPointer = @ItemlocRowPointer output

      IF (@Severity > 0)
         GOTO EOF

      IF @CoShipmentApprovalRequired = 0
      BEGIN
        select
         @ItemlocWhse = itemloc.whse
        ,@ItemlocItem = itemloc.item
        ,@ItemlocLoc = itemloc.loc
        ,@ItemlocMrbFlag = itemloc.mrb_flag
        ,@ItemlocLocType = itemloc.loc_type
        ,@ItemlocQtyOnHand = itemloc.qty_on_hand
        ,@ItemlocInvAcct = itemloc.inv_acct
        ,@ItemlocLbrAcct = itemloc.lbr_acct
        ,@ItemlocFovhdAcct = itemloc.fovhd_acct
        ,@ItemlocVovhdAcct = itemloc.vovhd_acct
        ,@ItemlocOutAcct = itemloc.out_acct
        ,@ItemlocInvAcctUnit1 = itemloc.inv_acct_unit1
        ,@ItemlocInvAcctUnit2 = itemloc.inv_acct_unit2
        ,@ItemlocInvAcctUnit3 = itemloc.inv_acct_unit3
        ,@ItemlocInvAcctUnit4 = itemloc.inv_acct_unit4
        ,@ItemlocLbrAcctUnit1 = itemloc.lbr_acct_unit1
        ,@ItemlocLbrAcctUnit2 = itemloc.lbr_acct_unit2
        ,@ItemlocLbrAcctUnit3 = itemloc.lbr_acct_unit3
        ,@ItemlocLbrAcctUnit4 = itemloc.lbr_acct_unit4
        ,@ItemlocFovhdAcctUnit1 = itemloc.fovhd_acct_unit1
        ,@ItemlocFovhdAcctUnit2 = itemloc.fovhd_acct_unit2
        ,@ItemlocFovhdAcctUnit3 = itemloc.fovhd_acct_unit3
        ,@ItemlocFovhdAcctUnit4 = itemloc.fovhd_acct_unit4
        ,@ItemlocVovhdAcctUnit1 = itemloc.vovhd_acct_unit1
        ,@ItemlocVovhdAcctUnit2 = itemloc.vovhd_acct_unit2
        ,@ItemlocVovhdAcctUnit3 = itemloc.vovhd_acct_unit3
        ,@ItemlocVovhdAcctUnit4 = itemloc.vovhd_acct_unit4
        ,@ItemlocOutAcctUnit1 = itemloc.out_acct_unit1
        ,@ItemlocOutAcctUnit2 = itemloc.out_acct_unit2
        ,@ItemlocOutAcctUnit3 = itemloc.out_acct_unit3
        ,@ItemlocOutAcctUnit4 = itemloc.out_acct_unit4
        ,@ItemlocLbrCost = itemloc.lbr_cost
        ,@ItemlocMatlCost = itemloc.matl_cost
        ,@ItemlocFovhdCost = itemloc.fovhd_cost
        ,@ItemlocVovhdCost = itemloc.vovhd_cost
        ,@ItemlocOutCost = itemloc.out_cost
        ,@ItemlocUnitCost = itemloc.unit_cost
        ,@ItemlocPermFlag = itemloc.perm_flag
         ,@ItemlifoItemlocInvAcct = itemloc.inv_acct
         ,@ItemlifoItemlocLbrAcct = itemloc.lbr_acct
         ,@ItemlifoItemlocFovhdAcct = itemloc.fovhd_acct
         ,@ItemlifoItemlocVovhdAcct = itemloc.vovhd_acct
         ,@ItemlifoItemlocOutAcct = itemloc.out_acct
         ,@ItemlifoItemlocInvAcctUnit1 = itemloc.inv_acct_unit1
         ,@ItemlifoItemlocInvAcctUnit2 = itemloc.inv_acct_unit2
         ,@ItemlifoItemlocInvAcctUnit3 = itemloc.inv_acct_unit3
         ,@ItemlifoItemlocInvAcctUnit4 = itemloc.inv_acct_unit4
         ,@ItemlifoItemlocLbrAcctUnit1 = itemloc.lbr_acct_unit1
         ,@ItemlifoItemlocLbrAcctUnit2 = itemloc.lbr_acct_unit2
         ,@ItemlifoItemlocLbrAcctUnit3 = itemloc.lbr_acct_unit3
         ,@ItemlifoItemlocLbrAcctUnit4 = itemloc.lbr_acct_unit4
         ,@ItemlifoItemlocFovhdAcctUnit1 = itemloc.fovhd_acct_unit1
         ,@ItemlifoItemlocFovhdAcctUnit2 = itemloc.fovhd_acct_unit2
         ,@ItemlifoItemlocFovhdAcctUnit3 = itemloc.fovhd_acct_unit3
         ,@ItemlifoItemlocFovhdAcctUnit4 = itemloc.fovhd_acct_unit4
         ,@ItemlifoItemlocVovhdAcctUnit1 = itemloc.vovhd_acct_unit1
         ,@ItemlifoItemlocVovhdAcctUnit2 = itemloc.vovhd_acct_unit2
         ,@ItemlifoItemlocVovhdAcctUnit3 = itemloc.vovhd_acct_unit3
         ,@ItemlifoItemlocVovhdAcctUnit4 = itemloc.vovhd_acct_unit4
         ,@ItemlifoItemlocOutAcctUnit1 = itemloc.out_acct_unit1
         ,@ItemlifoItemlocOutAcctUnit2 = itemloc.out_acct_unit2
         ,@ItemlifoItemlocOutAcctUnit3 = itemloc.out_acct_unit3
         ,@ItemlifoItemlocOutAcctUnit4 = itemloc.out_acct_unit4
        from itemloc WITH (UPDLOCK)
        where itemloc.RowPointer = @ItemlocRowPointer
      END
      ELSE
      BEGIN
        select
         @ItemlocWhse = itemloc.whse
        ,@ItemlocItem = itemloc.item
        ,@ItemlocLoc = itemloc.loc
        ,@ItemlocMrbFlag = itemloc.mrb_flag
        ,@ItemlocLocType = itemloc.loc_type
        ,@ItemlocQtyOnHand = itemloc.qty_on_hand
        ,@ItemlocInvAcct = itemloc.inv_in_proc_acct
        ,@ItemlocLbrAcct = itemloc.lbr_in_proc_acct
        ,@ItemlocFovhdAcct = itemloc.fovhd_in_proc_acct
        ,@ItemlocVovhdAcct = itemloc.vovhd_in_proc_acct
        ,@ItemlocOutAcct = itemloc.out_in_proc_acct
        ,@ItemlocInvAcctUnit1 = itemloc.inv_in_proc_acct_unit1
        ,@ItemlocInvAcctUnit2 = itemloc.inv_in_proc_acct_unit2
        ,@ItemlocInvAcctUnit3 = itemloc.inv_in_proc_acct_unit3
        ,@ItemlocInvAcctUnit4 = itemloc.inv_in_proc_acct_unit4
        ,@ItemlocLbrAcctUnit1 = itemloc.lbr_in_proc_acct_unit1
        ,@ItemlocLbrAcctUnit2 = itemloc.lbr_in_proc_acct_unit2
        ,@ItemlocLbrAcctUnit3 = itemloc.lbr_in_proc_acct_unit3
        ,@ItemlocLbrAcctUnit4 = itemloc.lbr_in_proc_acct_unit4
        ,@ItemlocFovhdAcctUnit1 = itemloc.fovhd_in_proc_acct_unit1
        ,@ItemlocFovhdAcctUnit2 = itemloc.fovhd_in_proc_acct_unit2
        ,@ItemlocFovhdAcctUnit3 = itemloc.fovhd_in_proc_acct_unit3
        ,@ItemlocFovhdAcctUnit4 = itemloc.fovhd_in_proc_acct_unit4
        ,@ItemlocVovhdAcctUnit1 = itemloc.vovhd_in_proc_acct_unit1
        ,@ItemlocVovhdAcctUnit2 = itemloc.vovhd_in_proc_acct_unit2
        ,@ItemlocVovhdAcctUnit3 = itemloc.vovhd_in_proc_acct_unit3
        ,@ItemlocVovhdAcctUnit4 = itemloc.vovhd_in_proc_acct_unit4
        ,@ItemlocOutAcctUnit1 = itemloc.out_in_proc_acct_unit1
        ,@ItemlocOutAcctUnit2 = itemloc.out_in_proc_acct_unit2
        ,@ItemlocOutAcctUnit3 = itemloc.out_in_proc_acct_unit3
        ,@ItemlocOutAcctUnit4 = itemloc.out_in_proc_acct_unit4
        ,@ItemlocLbrCost = itemloc.lbr_cost
        ,@ItemlocMatlCost = itemloc.matl_cost
        ,@ItemlocFovhdCost = itemloc.fovhd_cost
        ,@ItemlocVovhdCost = itemloc.vovhd_cost
        ,@ItemlocOutCost = itemloc.out_cost
        ,@ItemlocUnitCost = itemloc.unit_cost
        ,@ItemlocPermFlag = itemloc.perm_flag
         ,@ItemlifoItemlocInvAcct = itemloc.inv_acct
         ,@ItemlifoItemlocLbrAcct = itemloc.lbr_acct
         ,@ItemlifoItemlocFovhdAcct = itemloc.fovhd_acct
         ,@ItemlifoItemlocVovhdAcct = itemloc.vovhd_acct
         ,@ItemlifoItemlocOutAcct = itemloc.out_acct
         ,@ItemlifoItemlocInvAcctUnit1 = itemloc.inv_acct_unit1
         ,@ItemlifoItemlocInvAcctUnit2 = itemloc.inv_acct_unit2
         ,@ItemlifoItemlocInvAcctUnit3 = itemloc.inv_acct_unit3
         ,@ItemlifoItemlocInvAcctUnit4 = itemloc.inv_acct_unit4
         ,@ItemlifoItemlocLbrAcctUnit1 = itemloc.lbr_acct_unit1
         ,@ItemlifoItemlocLbrAcctUnit2 = itemloc.lbr_acct_unit2
         ,@ItemlifoItemlocLbrAcctUnit3 = itemloc.lbr_acct_unit3
         ,@ItemlifoItemlocLbrAcctUnit4 = itemloc.lbr_acct_unit4
         ,@ItemlifoItemlocFovhdAcctUnit1 = itemloc.fovhd_acct_unit1
         ,@ItemlifoItemlocFovhdAcctUnit2 = itemloc.fovhd_acct_unit2
         ,@ItemlifoItemlocFovhdAcctUnit3 = itemloc.fovhd_acct_unit3
         ,@ItemlifoItemlocFovhdAcctUnit4 = itemloc.fovhd_acct_unit4
         ,@ItemlifoItemlocVovhdAcctUnit1 = itemloc.vovhd_acct_unit1
         ,@ItemlifoItemlocVovhdAcctUnit2 = itemloc.vovhd_acct_unit2
         ,@ItemlifoItemlocVovhdAcctUnit3 = itemloc.vovhd_acct_unit3
         ,@ItemlifoItemlocVovhdAcctUnit4 = itemloc.vovhd_acct_unit4
         ,@ItemlifoItemlocOutAcctUnit1 = itemloc.out_acct_unit1
         ,@ItemlifoItemlocOutAcctUnit2 = itemloc.out_acct_unit2
         ,@ItemlifoItemlocOutAcctUnit3 = itemloc.out_acct_unit3
         ,@ItemlifoItemlocOutAcctUnit4 = itemloc.out_acct_unit4
        from itemloc WITH (UPDLOCK)
        where itemloc.RowPointer = @ItemlocRowPointer
      END
   END

   IF (@CoShipmentApprovalRequired = 1) and (@ItemCostMethod = 'F')
   BEGIN
      IF @ItemlocVovhdAcct IS NULL
         SET @ItemInvAcctMsg = '@itemloc.vovhd_in_proc_acct'
      IF @ItemlocFovhdAcct IS NULL
         SET @ItemInvAcctMsg = '@itemloc.fovhd_in_proc_acct'
      IF @ItemlocLbrAcct IS NULL
         SET @ItemInvAcctMsg = '@itemloc.lbr_in_proc_acct'
      IF @ItemlocInvAcct IS NULL
         SET @ItemInvAcctMsg = '@itemloc.inv_in_proc_acct'

      IF @ItemInvAcctMsg IS NOT NULL
      BEGIN
         EXEC @Severity = dbo.MsgAppSp @Infobar OUTPUT, 'E=NoExist2'
         , '@!Account'
         , '@chart.acct'
         , @ItemlocInvAcct
         , '@site'
         , @ParmsSite

         EXEC @Severity = dbo.MsgAppSp @Infobar OUTPUT, 'I=IsCompare', '@chart.acct', @ItemInvAcctMsg

         EXEC @Severity = dbo.MsgAppSp @Infobar OUTPUT, 'I=IsCompare0', '@prodcode.product_code', @ProdcodeProductCode, '@distacct'

         GOTO EOF
      END
   END

   if @ItemLotTracked <> 0
   BEGIN
      select
       @LotLocRowPointer = lot_loc.RowPointer
      ,@LotLocLbrCost = lot_loc.lbr_cost
      ,@LotLocMatlCost = lot_loc.matl_cost
      ,@LotLocFovhdCost = lot_loc.fovhd_cost
      ,@LotLocVovhdCost = lot_loc.vovhd_cost
      ,@LotLocOutCost = lot_loc.out_cost
      ,@LotLocWhse = lot_loc.whse
      ,@LotLocItem = lot_loc.item
      ,@LotLocLoc = lot_loc.loc
      ,@LotLocLot = lot_loc.lot
      ,@LotLocQtyOnHand = lot_loc.qty_on_hand
      ,@LotLocUnitCost = lot_loc.unit_cost
      from lot_loc WITH (UPDLOCK)
      where lot_loc.whse = @ItemlocWhse
         and lot_loc.item = @ItemlocItem
         and lot_loc.loc = @ItemlocLoc
         and lot_loc.lot = @SLot
      if @@rowcount <> 1
         set @LotLocRowPointer = null

      if @LotLocRowPointer is null
      BEGIN
         IF @OKtoCreateLotLoc <> 0
         BEGIN
            set @LotLocRowPointer = newid()
            -- INITIALIZING VARS FOR TABLE INSERT
            SET @LotLocLbrCost   = (0)
            SET @LotLocMatlCost  = (0)
            SET @LotLocFovhdCost = (0)
            SET @LotLocVovhdCost = (0)
            SET @LotLocOutCost   = (0)

            SET @LotLocWhse = @ItemlocWhse
            SET @LotLocItem = @ItemlocItem
            SET @LotLocLoc  = @ItemlocLoc
            SET @LotLocLot  = @SLot
            SET @LotLocQtyOnHand = 0

            insert into lot_loc (RowPointer, whse, item, loc, lot, qty_on_hand)
            values(@LotLocRowPointer, @LotLocWhse, @LotLocItem, @LotLocLoc, @LotLocLot, @LotLocQtyOnHand)
         end
         ELSE
         BEGIN
            EXEC @Severity = dbo.MsgAppSp @Infobar OUTPUT, 'I=NoExist4'
               , '@lot_loc'
               , '@lot_loc.whse'
               , @CoitemWhse
               , '@lot_loc.item'
               , @SItem
               , '@lot_loc.loc'
               , @SLoc
               , '@lot_loc.lot'
               , @SLot

            GOTO EOF
         END
      end
   end

   IF @ItemlocMrbFlag <> 0
   AND NOT ((@SReturn <> 0 and @SQty >= 0) or (@SReturn = 0 and @SQty <= 0))
   BEGIN
      EXEC @Severity = dbo.MsgAppSp @Infobar OUTPUT, 'I=IsCompare3'
         , '@itemloc.mrb_flag'
         , '@:ListYesNo:1'
         , '@itemloc'
         , '@itemloc.whse'
         , @CoitemWhse
         , '@itemloc.item'
         , @SItem
         , '@itemloc.loc'
         , @SLoc

      GOTO EOF
   end

   if @ItemlocLocType = 'T'
   BEGIN
      EXEC @Severity = dbo.MsgAppSp @Infobar OUTPUT, 'I=IsCompare3'
         , '@itemloc.loc_type'
         , '@:LocType:T' --'@:ItemlocLocType:T'
         , '@itemloc'
         , '@itemloc.whse'
         , @CoitemWhse
         , '@itemloc.item'
         , @SItem
         , '@itemloc.loc'
         , @SLoc

      GOTO EOF
   end

   /* re-validate quantities */
   IF @SReturn <> 0
   BEGIN
      /* RETURN INVOICED QTY */
      if @SQty > 0.0
      BEGIN
         if @SQty > @CoitemQtyInvoiced - @CoitemQtyReturned
         BEGIN
            BEGIN
               SET @MsgParm2 = dbo.UomConvQty(@CoitemQtyInvoiced - @CoitemQtyReturned, @UomConvFactor, 'From Base')

               EXEC @MsgSeverity = dbo.MsgAppSp @Infobar OUTPUT, 'E=NoCompare>'
                  , '@coitem.qty_shipped', @MsgParm2
               IF @MsgSeverity >= ISNULL(@Severity, 0)
                  SET @Severity = @MsgSeverity
            END

            GOTO EOF
         end
      end
      else
      BEGIN
         /* s-qty <= 0.0 */
         if - @SQty > @ItemlocQtyOnHand
         BEGIN
            IF @InvparmsNegFlag = 0
            BEGIN
               BEGIN
                  SET @MsgParm2 = - @ItemlocQtyOnHand

                  EXEC @MsgSeverity = dbo.MsgAppSp @Infobar OUTPUT, 'E=NoCompare<'
                     , '@coitem.qty_shipped', @MsgParm2
                  IF @MsgSeverity >= ISNULL(@Severity, 0)
                     SET @Severity = @MsgSeverity
               END

               EXEC @Severity = dbo.MsgAppSp @Infobar OUTPUT, 'I=IsCompare3'
                  , '@itemloc.qty_on_hand'
                  , @ItemlocQtyOnHand
                  , '@itemloc'
                  , '@itemloc.whse'
                  , @CoitemWhse
                  , '@itemloc.item'
                  , @SItem
                  , '@itemloc.loc'
                  , @SLoc

               GOTO EOF
            end
         end

         if @ItemLotTracked <> 0 and (@LotLocRowPointer is not null)
         BEGIN
            if - @SQty > @LotLocQtyOnHand
            BEGIN
               if @InvparmsNegFlag = 0
               BEGIN
                  BEGIN
                     SET @MsgParm2 = - @LotLocQtyOnHand

                     EXEC @MsgSeverity = dbo.MsgAppSp @Infobar OUTPUT, 'E=NoCompare<'
                        , '@coitem.qty_shipped', @MsgParm2
                     IF @MsgSeverity >= ISNULL(@Severity, 0)
                        SET @Severity = @MsgSeverity
                  END

                  EXEC @Severity = dbo.MsgAppSp @Infobar OUTPUT, 'I=IsCompare4'
                     , '@lot_loc.qty_on_hand'
                     , @LotLocQtyOnHand
                     , '@itemloc'
                     , '@itemloc.whse'
                     , @CoitemWhse
                     , '@itemloc.item'
                     , @SItem
                     , '@itemloc.loc'
                     , @SLoc
                     , '@lot_loc.lot'
                     , @SLot

                  GOTO EOF
               end
            end
         end

         if - @SQty > @CoitemQtyReturned
         BEGIN
            BEGIN
               SET @MsgParm2 = - @CoitemQtyReturned

               EXEC @MsgSeverity = dbo.MsgAppSp @Infobar OUTPUT, 'E=NoCompare<'
                  , '@coitem.qty_shipped', @MsgParm2
               IF @MsgSeverity >= ISNULL(@Severity, 0)
                  SET @Severity = @MsgSeverity
            END

            GOTO EOF
         end
      end
   end
   else
   BEGIN
      /* if not s-return */
      if @SQty > 0.0
      BEGIN
         if @SQty > @ItemlocQtyOnHand
         BEGIN
            if @InvparmsNegFlag = 0
            BEGIN
               EXEC @Severity = dbo.MsgAppSp @Infobar OUTPUT, 'E=NoCompare>'
                  , '@coitem.qty_shipped'
                  , @ItemlocQtyOnHand

               EXEC @Severity = dbo.MsgAppSp @Infobar OUTPUT, 'I=IsCompare3'
                  , '@itemloc.qty_on_hand'
                  , @ItemlocQtyOnHand
                  , '@itemloc'
                  , '@itemloc.whse'
                  , @CoitemWhse
                  , '@itemloc.item'
                  , @SItem
                  , '@itemloc.loc'
                  , @SLoc

               GOTO EOF
            end
         end

         if @ItemLotTracked <> 0 and (@LotLocRowPointer is not null)
         BEGIN
            if @SQty > @LotLocQtyOnHand
            BEGIN
               if @InvparmsNegFlag = 0
               BEGIN
                  EXEC @Severity = dbo.MsgAppSp @Infobar OUTPUT, 'E=NoCompare>'
                     , '@coitem.qty_shipped'
                     , @LotLocQtyOnHand

                  EXEC @Severity = dbo.MsgAppSp @Infobar OUTPUT, 'I=IsCompare4'
                     , '@itemloc.qty_on_hand'
                     , @LotLocQtyOnHand
                     , '@itemloc'
                     , '@itemloc.whse'
                     , @CoitemWhse
                     , '@itemloc.item'
                     , @SItem
                     , '@itemloc.loc'
                     , @SLoc
                     , '@lot_loc.lot'
                     , @SLot

                 GOTO EOF
               end
            end
         end
      end
      else
      BEGIN
         if round(@SQty - (@CoitemQtyInvoiced - @CoitemQtyShipped - @CoitemQtyReturned), @PlacesQtyUnit) < 0
         BEGIN
            BEGIN
               SET @MsgParm2 = dbo.UomConvQty(@CoitemQtyInvoiced - @CoitemQtyShipped - @CoitemQtyReturned, @UomConvFactor, 'From Base')

               EXEC @MsgSeverity = dbo.MsgAppSp @Infobar OUTPUT, 'E=NoCompare<'
                  , '@coitem.qty_shipped', @MsgParm2
               IF @MsgSeverity >= ISNULL(@Severity, 0)
                  SET @Severity = @MsgSeverity
            END

            GOTO EOF
         end
      end
   end
   END

   /* POST MATERIAL TRANSACTION */
   set @MatltranRowPointer  = newid()
   -- INITIALIZING VARS FOR TABLE INSERT
   SET @MatltranLbrCost     = (0)
   SET @MatltranMatlCost    = (0)
   SET @MatltranFovhdCost   = (0)
   SET @MatltranVovhdCost   = (0)
   SET @MatltranOutCost     = (0)
   SET @MatltranCost        = (0)

   SET @MatltranRefType    = 'O'
   SET @MatltranRefNum     = @SCoNum
   SET @MatltranRefLineSuf = @SCoLine
   SET @MatltranRefRelease = @SCoRel
   SET @MatltranTransType  = CASE WHEN @SReturn <> 0 then 'W' else 'S' END
   SET @MatltranQty        = CASE WHEN @SReturn <> 0 then @SQty else (- @SQty) END
   SET @MatltranTransDate  = @STransDate
   SET @MatltranItem       = @SItem
   SET @MatltranWhse       = @CoitemWhse
   SET @MatltranLoc        = @ItemlocLoc
   SET @MatltranLot        = @SLot
   SET @MatltranUserCode   = @UserCode
   SET @MatltranReasonCode = @SReasonCode
   SET @MatltranShipDateSeq = @CoShipDateSeq
   SET @TAdjQty            = @MatltranQty

   DECLARE
      @ProcName sysname
      -- Name of current procedure
      SET @ProcName = OBJECT_NAME(@@PROCID)

   /***************************** COSTING *****************************/
   IF @NonInventoryItem = 1
   BEGIN /* Start Non-Inventory Item Costing */
      IF (@CoShipRowPointer is not null)
      BEGIN
         SET @CoShipLbrCost   = @MatltranLbrCost
         SET @CoShipMatlCost  = @MatltranMatlCost
         SET @CoShipFovhdCost = @MatltranFovhdCost
         SET @CoShipVovhdCost = @MatltranVovhdCost
         SET @CoShipOutCost   = @MatltranOutCost

         SET @CoShipMatlCost  = @CoitemCost
         SET @CoShipCost = @CoShipLbrCost + @CoShipMatlCost + @CoShipFovhdCost + @CoShipVovhdCost + @CoShipOutCost

         set @AvgMatlCost = @CoShipMatlCost
         set @AvgLbrCost = @CoShipLbrCost
         set @AvgFovhdCost = @CoShipFovhdCost
         set @AvgVovhdCost = @CoShipVovhdCost
         set @AvgOutCost = @CoShipOutCost

         UPDATE co_ship
         SET
          lbr_cost   = @CoShipLbrCost
         ,matl_cost  = @CoShipMatlCost
         ,fovhd_cost = @CoShipFovhdCost
         ,vovhd_cost = @CoShipVovhdCost
         ,out_cost   = @CoShipOutCost
         ,cost       = @CoShipCost
         WHERE RowPointer = @CoShipRowPointer
      END

   SET @MatltranCost     = @CoShipCost
   SET @MatltranMatlCost = @CoShipMatlCost
   SET @MatltranLoc      = @SLoc

   INSERT INTO matltran (RowPointer, ref_type, ref_num, ref_line_suf, ref_release
   , trans_type, qty, trans_date, item, whse, loc, lot, user_code, reason_code
   , lbr_cost, matl_cost, fovhd_cost, vovhd_cost, out_cost, cost, import_doc_id
   , emp_num, date_seq)
   VALUES(@MatltranRowPointer, @MatltranRefType, @MatltranRefNum, @MatltranRefLineSuf, @MatltranRefRelease
   , @MatltranTransType, @MatltranQty, @MatltranTransDate, @MatltranItem, 
   @MatltranWhse, @MatltranLoc, @MatltranLot, @MatltranUserCode, @MatltranReasonCode
   , @MatltranLbrCost, @MatltranMatlCost, @MatltranFovhdCost, @MatltranVovhdCost, @MatltranOutCost, @MatltranCost, @ImportDocId
   , @EmpNum, @MatltranShipDateSeq)

   SELECT @MatltranTransNum = trans_num
   FROM matltran
   WHERE RowPointer = @MatltranRowPointer
   
   
   -- _KPI 03/22/17 - 
   update _KPI_BarCodes
   set MatlTransNum = @MatltranTransNum
   
   from _KPI_BarCodes Barcode
   where 
   RefNum = @SCoNum and 
   RefLine = @SCoLine and
--   lot  = isnull(@MatltranLot, '') and
   barcode.UserId = dbo.UserId() and
   MatlTransNum = 0
   

   
   SET @TTotPostMatl = @TAdjQty * @CoitemCost
   SET @TTotPostMatl  = round(@TTotPostMatl, @TDomPlaces)

   SET @MatltranAmt1RowPointer = newid()
   SET @MatltranAmt1TransNum = @MatltranTransNum
   SET @MatltranAmt1TransSeq = 1
   SET @MatltranAmt1LbrAmt   = 0
   SET @MatltranAmt1MatlAmt  = - (@TTotPostMatl)
   SET @MatltranAmt1FovhdAmt = 0
   SET @MatltranAmt1VovhdAmt = 0
   SET @MatltranAmt1OutAmt   = 0

   SET @MatltranAmt1Amt = @MatltranAmt1LbrAmt + @MatltranAmt1MatlAmt + @MatltranAmt1FovhdAmt + @MatltranAmt1VovhdAmt + @MatltranAmt1OutAmt

   SET @MatltranAmt1Acct = NULL /* COGS */
   SET @MatltranAmt1LbrAcct   = NULL
   SET @MatltranAmt1LbrAcctUnit1   = NULL
   SET @MatltranAmt1LbrAcctUnit2   = NULL
   SET @MatltranAmt1LbrAcctUnit3   = NULL
   SET @MatltranAmt1LbrAcctUnit4   = NULL
   SET @MatltranAmt1MatlAcct  = @TCgsAcct
   SET @MatltranAmt1MatlAcctUnit1  = @TCgsAcctUnit1
   SET @MatltranAmt1MatlAcctUnit2  = @TCgsAcctUnit2
   SET @MatltranAmt1MatlAcctUnit3  = @TCgsAcctUnit3
   SET @MatltranAmt1MatlAcctUnit4  = @TCgsAcctUnit4
   SET @MatltranAmt1FovhdAcct = NULL
   SET @MatltranAmt1FovhdAcctUnit1 = NULL
   SET @MatltranAmt1FovhdAcctUnit2 = NULL
   SET @MatltranAmt1FovhdAcctUnit3 = NULL
   SET @MatltranAmt1FovhdAcctUnit4 = NULL
   SET @MatltranAmt1VovhdAcct = NULL
   SET @MatltranAmt1VovhdAcctUnit1 = NULL
   SET @MatltranAmt1VovhdAcctUnit2 = NULL
   SET @MatltranAmt1VovhdAcctUnit3 = NULL
   SET @MatltranAmt1VovhdAcctUnit4 = NULL
   SET @MatltranAmt1OutAcct   = NULL
   SET @MatltranAmt1OutAcctUnit1   = NULL
   SET @MatltranAmt1OutAcctUnit2   = NULL
   SET @MatltranAmt1OutAcctUnit3   = NULL
   SET @MatltranAmt1OutAcctUnit4   = NULL

   INSERT INTO matltran_amt (RowPointer, trans_num, trans_seq
   , lbr_amt, matl_amt, fovhd_amt, vovhd_amt, out_amt, amt
   , acct, lbr_acct, lbr_acct_unit1, lbr_acct_unit2, lbr_acct_unit3, lbr_acct_unit4
   , matl_acct, matl_acct_unit1, matl_acct_unit2, matl_acct_unit3, matl_acct_unit4
   , fovhd_acct, fovhd_acct_unit1, fovhd_acct_unit2, fovhd_acct_unit3, fovhd_acct_unit4
   , vovhd_acct, vovhd_acct_unit1, vovhd_acct_unit2, vovhd_acct_unit3, vovhd_acct_unit4
   , out_acct, out_acct_unit1, out_acct_unit2, out_acct_unit3, out_acct_unit4)
   VALUES(@MatltranAmt1RowPointer, @MatltranAmt1TransNum, @MatltranAmt1TransSeq
   , @MatltranAmt1LbrAmt, @MatltranAmt1MatlAmt, @MatltranAmt1FovhdAmt, @MatltranAmt1VovhdAmt, @MatltranAmt1OutAmt, @MatltranAmt1Amt
   , @MatltranAmt1Acct, @MatltranAmt1LbrAcct, @MatltranAmt1LbrAcctUnit1, @MatltranAmt1LbrAcctUnit2, @MatltranAmt1LbrAcctUnit3, @MatltranAmt1LbrAcctUnit4
   , @MatltranAmt1MatlAcct, @MatltranAmt1MatlAcctUnit1, @MatltranAmt1MatlAcctUnit2, @MatltranAmt1MatlAcctUnit3, @MatltranAmt1MatlAcctUnit4
   , @MatltranAmt1FovhdAcct, @MatltranAmt1FovhdAcctUnit1, @MatltranAmt1FovhdAcctUnit2, @MatltranAmt1FovhdAcctUnit3, @MatltranAmt1FovhdAcctUnit4
   , @MatltranAmt1VovhdAcct, @MatltranAmt1VovhdAcctUnit1, @MatltranAmt1VovhdAcctUnit2, @MatltranAmt1VovhdAcctUnit3, @MatltranAmt1VovhdAcctUnit4
   , @MatltranAmt1OutAcct, @MatltranAmt1OutAcctUnit1, @MatltranAmt1OutAcctUnit2, @MatltranAmt1OutAcctUnit3, @MatltranAmt1OutAcctUnit4)

   SET @MatltranAmt2RowPointer = newid()
   SET @MatltranAmt2TransNum = @MatltranTransNum
   SET @MatltranAmt2TransSeq = 2
   SET @MatltranAmt2LbrAmt   = 0
   SET @MatltranAmt2MatlAmt  = @TTotPostMatl
   SET @MatltranAmt2FovhdAmt = 0
   SET @MatltranAmt2VovhdAmt = 0
   SET @MatltranAmt2OutAmt   = 0

   SET @MatltranAmt2Amt = @MatltranAmt2LbrAmt + @MatltranAmt2MatlAmt + @MatltranAmt2FovhdAmt + @MatltranAmt2VovhdAmt + @MatltranAmt2OutAmt

   SET @MatltranAmt2Acct = NULL  /* INVENTORY ACCT */

   SET @MatltranAmt2MatlAcct = @DistacctInvMatlAcct
   SET @MatltranAmt2MatlAcctUnit1 = @DistacctInvMatlAcctUnit1
   SET @MatltranAmt2MatlAcctUnit2 = @DistacctInvMatlAcctUnit2
   SET @MatltranAmt2MatlAcctUnit3 = @DistacctInvMatlAcctUnit3
   SET @MatltranAmt2MatlAcctUnit4 = @DistacctInvMatlAcctUnit4
   SET @MatltranAmt2LbrAcct = NULL
   SET @MatltranAmt2LbrAcctUnit1 = NULL
   SET @MatltranAmt2LbrAcctUnit2 = NULL
   SET @MatltranAmt2LbrAcctUnit3 = NULL
   SET @MatltranAmt2LbrAcctUnit4 = NULL
   SET @MatltranAmt2FovhdAcct = NULL
   SET @MatltranAmt2FovhdAcctUnit1 = NULL
   SET @MatltranAmt2FovhdAcctUnit2 = NULL
   SET @MatltranAmt2FovhdAcctUnit3 = NULL
   SET @MatltranAmt2FovhdAcctUnit4 = NULL
   SET @MatltranAmt2VovhdAcct = NULL
   SET @MatltranAmt2VovhdAcctUnit1 = NULL
   SET @MatltranAmt2VovhdAcctUnit2 = NULL
   SET @MatltranAmt2VovhdAcctUnit3 = NULL
   SET @MatltranAmt2VovhdAcctUnit4 = NULL
   SET @MatltranAmt2OutAcct = NULL
   SET @MatltranAmt2OutAcctUnit1 = NULL
   SET @MatltranAmt2OutAcctUnit2 = NULL
   SET @MatltranAmt2OutAcctUnit3 = NULL
   SET @MatltranAmt2OutAcctUnit4 = NULL

   INSERT INTO matltran_amt (RowPointer, trans_num, trans_seq
   , lbr_amt, matl_amt, fovhd_amt, vovhd_amt, out_amt, amt
   , acct, matl_acct, matl_acct_unit1, matl_acct_unit2, matl_acct_unit3, matl_acct_unit4
   , lbr_acct, lbr_acct_unit1, lbr_acct_unit2, lbr_acct_unit3, lbr_acct_unit4
   , fovhd_acct, fovhd_acct_unit1, fovhd_acct_unit2, fovhd_acct_unit3, fovhd_acct_unit4
   , vovhd_acct, vovhd_acct_unit1, vovhd_acct_unit2, vovhd_acct_unit3, vovhd_acct_unit4
   , out_acct, out_acct_unit1, out_acct_unit2, out_acct_unit3, out_acct_unit4, include_in_inventory_bal_calc)
   VALUES(@MatltranAmt2RowPointer, @MatltranAmt2TransNum, @MatltranAmt2TransSeq
   , @MatltranAmt2LbrAmt, @MatltranAmt2MatlAmt, @MatltranAmt2FovhdAmt, @MatltranAmt2VovhdAmt, @MatltranAmt2OutAmt, @MatltranAmt2Amt
   , @MatltranAmt2Acct, @DistacctInvMatlAcct, @DistacctInvMatlAcctUnit1, @DistacctInvMatlAcctUnit2, @DistacctInvMatlAcctUnit3, @DistacctInvMatlAcctUnit4
   , @MatltranAmt2LbrAcct, @MatltranAmt2LbrAcctUnit1, @MatltranAmt2LbrAcctUnit2, @MatltranAmt2LbrAcctUnit3, @MatltranAmt2LbrAcctUnit4
   , @MatltranAmt2FovhdAcct, @MatltranAmt2FovhdAcctUnit1, @MatltranAmt2FovhdAcctUnit2, @MatltranAmt2FovhdAcctUnit3, @MatltranAmt2FovhdAcctUnit4
   , @MatltranAmt2VovhdAcct, @MatltranAmt2VovhdAcctUnit1, @MatltranAmt2VovhdAcctUnit2, @MatltranAmt2VovhdAcctUnit3, @MatltranAmt2VovhdAcctUnit4
   , @MatltranAmt2OutAcct, @MatltranAmt2OutAcctUnit1, @MatltranAmt2OutAcctUnit2, @MatltranAmt2OutAcctUnit3, @MatltranAmt2OutAcctUnit4, 1)

   IF @ParmsPostJour <> 0
      BEGIN

         SET @TRef = CASE WHEN @SReturn <> 0 THEN 'INV CRT ' ELSE 'INV CSH ' END

         IF ISNULL(@MatltranAmt1MatlAmt, 0) != 0
         OR ISNULL(@MatltranAmt1LbrAmt, 0) != 0
         OR ISNULL(@MatltranAmt1FovhdAmt, 0) != 0
         OR ISNULL(@MatltranAmt1VovhdAmt, 0) != 0
         OR ISNULL(@MatltranAmt1OutAmt, 0) != 0
         OR ISNULL(@MatltranAmt2MatlAmt, 0) != 0
         OR ISNULL(@MatltranAmt2LbrAmt, 0) != 0
         OR ISNULL(@MatltranAmt2FovhdAmt, 0) != 0
         OR ISNULL(@MatltranAmt2VovhdAmt, 0) != 0
         OR ISNULL(@MatltranAmt2OutAmt, 0) != 0
         OR ISNULL(@MatltranAmt3Amt, 0) !=0
         BEGIN
            SET @ControlSite = @ParmsSite
            EXEC @Severity = dbo.NextControlNumberSp
              @JournalId = @TId
            , @TransDate = @MatltranTransDate
            , @ControlPrefix = @ControlPrefix OUTPUT
            , @ControlSite = @ControlSite OUTPUT
            , @ControlYear = @ControlYear OUTPUT
            , @ControlPeriod = @ControlPeriod OUTPUT
            , @ControlNumber = @ControlNumber OUTPUT
            , @Infobar = @Infobar OUTPUT

            IF (@Severity >= 5)
               GOTO EOF
         END

         IF @CoShipmentApprovalRequired = 0
            SET @Tacct_label = '@distacct.cgs_acct'
         ELSE
            SET @Tacct_label = '@distacct.cgs_in_proc_matl_acct'
         /* DR CGS Material Account for Non-Inventory Item */
         EXEC @Severity = dbo.InvJourSp
            @JournalId = @TId
            , @acct       = @MatltranAmt1MatlAcct
            , @acct_unit1 = @MatltranAmt1MatlAcctUnit1
            , @acct_unit2 = @MatltranAmt1MatlAcctUnit2
            , @acct_unit3 = @MatltranAmt1MatlAcctUnit3
            , @acct_unit4 = @MatltranAmt1MatlAcctUnit4
            , @amount      = @MatltranAmt1MatlAmt
            , @caller      = @ProcName
            , @occur       = 'DRCGSMatl'
            , @ref_type    = @MatltranRefType
            , @ref_num     = @CoCoNum
            , @ref_line_suf = @CoitemCoLine
            , @ref_release = @CoitemCoRelease
            , @ref = @TRef
            , @trans_date  = @MatltranTransDate
            , @trans_num   = @MatltranTransNum
            , @vend_num    = @CoCustNum
            , @acct_label  = @Tacct_label
            , @file_label  = '@distacct'
            , @key_label_1 = '@prodcode.product_code'
            , @key_value_1 = @ProdcodeProductCode
            , @keys        = 1
            , @curr_code = @CurrparmsCurrCode
            , @ParmsPostJour = @ParmsPostJour
            , @ControlPrefix = @ControlPrefix
            , @ControlSite = @ControlSite
            , @ControlYear = @ControlYear
            , @ControlPeriod = @ControlPeriod
            , @ControlNumber = @ControlNumber
            , @Infobar = @Infobar OUTPUT
         IF (@Severity >= 5)
            GOTO EOF

         IF @CoShipmentApprovalRequired = 0
            SET @Tacct_label = '@itemloc.inv_acct'
         ELSE
            SET @Tacct_label = '@itemloc.inv_in_proc_acct'
         /* CR Inv Material Account for Non-Inventory Item */
         EXEC @Severity = dbo.InvJourSp
            @JournalId = @TId
            , @acct       = @MatltranAmt2MatlAcct
            , @acct_unit1 = @MatltranAmt2MatlAcctUnit1
            , @acct_unit2 = @MatltranAmt2MatlAcctUnit2
            , @acct_unit3 = @MatltranAmt2MatlAcctUnit3
            , @acct_unit4 = @MatltranAmt2MatlAcctUnit4
            , @amount      = @MatltranAmt2MatlAmt
            , @caller      = @ProcName
            , @occur       = 'CRInvMatl'
            , @ref_type    = @MatltranRefType
            , @ref_num     = @CoCoNum
            , @ref_line_suf = @CoitemCoLine
            , @ref_release = @CoitemCoRelease
            , @ref = @TRef
            , @trans_date  = @MatltranTransDate
            , @trans_num   = @MatltranTransNum
            , @vend_num    = @CoCustNum
            , @acct_label  = @Tacct_label
            , @file_label  = '@itemloc'
            , @key_label_1 = '@itemloc.whse'
            , @key_value_1 = @ItemlocWhse
            , @key_label_2 = '@itemloc.item'
            , @key_value_2 = @ItemlocItem
            , @key_label_3 = '@itemloc.loc'
            , @key_value_3 = @ItemlocLoc
            , @keys        = 3
            , @curr_code = @CurrparmsCurrCode
            , @ParmsPostJour = @ParmsPostJour
            , @ControlPrefix = @ControlPrefix
            , @ControlSite = @ControlSite
            , @ControlYear = @ControlYear
            , @ControlPeriod = @ControlPeriod
            , @ControlNumber = @ControlNumber
            , @Infobar = @Infobar OUTPUT
         IF (@Severity >= 5)
            GOTO EOF

      END
   END /* End Non-Inventory Item Costing */
   ELSE
   BEGIN /* Start Inventory Item Costing */
      if @TAdjQty < 0
      BEGIN
         /* PULL FROM STOCK */
         /* SHIPPING TRANSACTION POSTED */
         if CHARINDEX( 'I', @ItemwhseCycleType) <> 0
            SET @ItemwhseCycleFlag = 1

         if - @TAdjQty >= @ItemlocQtyOnHand
         BEGIN
            if CHARINDEX( 'Z', @ItemwhseCycleType) <> 0
               SET @ItemwhseCycleFlag = 1
         end

         if @ItemLotTracked <> 0 and (@LotLocRowPointer is not null)
         BEGIN
            if CHARINDEX( 'Z', @ItemwhseCycleType) <> 0
            and - @TAdjQty >= @LotLocQtyOnHand
               SET @ItemwhseCycleFlag = 1
         end

         if @ItemCostMethod = 'A'
         BEGIN
            SET @TTotPostLbr   = @TAdjQty * @ItemLbrCost
            SET @TTotPostMatl  = @TAdjQty * @ItemMatlCost
            SET @TTotPostFovhd = @TAdjQty * @ItemFovhdCost
            SET @TTotPostVovhd = @TAdjQty * @ItemVovhdCost
            SET @TTotPostOut   = @TAdjQty * @ItemOutCost
         END
         else if @ItemCostMethod = 'L' or @ItemCostMethod = 'F'
         BEGIN
            SET @SQtyRem  = - @TAdjQty
            SET @TTotPostLbr   = 0
            SET @TTotPostMatl  = 0
            SET @TTotPostFovhd = 0
            SET @TTotPostVovhd = 0
            SET @TTotPostOut   = 0

            while @SQtyRem > 0
            BEGIN
               if @ItemCostMethod = 'F'
               begin
                  select top 1
                   @ItemlifoRowPointer = itemlifo.RowPointer
                  ,@ItemlifoItem = itemlifo.item
                  ,@ItemlifoInvAcct = itemlifo.inv_acct
                  ,@ItemlifoInvAcctUnit1 = itemlifo.inv_acct_unit1
                  ,@ItemlifoInvAcctUnit2 = itemlifo.inv_acct_unit2
                  ,@ItemlifoInvAcctUnit3 = itemlifo.inv_acct_unit3
                  ,@ItemlifoInvAcctUnit4 = itemlifo.inv_acct_unit4
                  ,@ItemlifoLbrAcct = itemlifo.lbr_acct
                  ,@ItemlifoLbrAcctUnit1 = itemlifo.lbr_acct_unit1
                  ,@ItemlifoLbrAcctUnit2 = itemlifo.lbr_acct_unit2
                  ,@ItemlifoLbrAcctUnit3 = itemlifo.lbr_acct_unit3
                  ,@ItemlifoLbrAcctUnit4 = itemlifo.lbr_acct_unit4
                  ,@ItemlifoFovhdAcct = itemlifo.fovhd_acct
                  ,@ItemlifoFovhdAcctUnit1 = itemlifo.fovhd_acct_unit1
                  ,@ItemlifoFovhdAcctUnit2 = itemlifo.fovhd_acct_unit2
                  ,@ItemlifoFovhdAcctUnit3 = itemlifo.fovhd_acct_unit3
                  ,@ItemlifoFovhdAcctUnit4 = itemlifo.fovhd_acct_unit4
                  ,@ItemlifoVovhdAcct = itemlifo.vovhd_acct
                  ,@ItemlifoVovhdAcctUnit1 = itemlifo.vovhd_acct_unit1
                  ,@ItemlifoVovhdAcctUnit2 = itemlifo.vovhd_acct_unit2
                  ,@ItemlifoVovhdAcctUnit3 = itemlifo.vovhd_acct_unit3
                  ,@ItemlifoVovhdAcctUnit4 = itemlifo.vovhd_acct_unit4
                  ,@ItemlifoOutAcct = itemlifo.out_acct
                  ,@ItemlifoOutAcctUnit1 = itemlifo.out_acct_unit1
                  ,@ItemlifoOutAcctUnit2 = itemlifo.out_acct_unit2
                  ,@ItemlifoOutAcctUnit3 = itemlifo.out_acct_unit3
                  ,@ItemlifoOutAcctUnit4 = itemlifo.out_acct_unit4
                  ,@ItemlifoTransDate = itemlifo.trans_date
                  ,@ItemlifoQty = itemlifo.qty
                  ,@ItemlifoLbrCost = itemlifo.lbr_cost
                  ,@ItemlifoMatlCost = itemlifo.matl_cost
                  ,@ItemlifoFovhdCost = itemlifo.fovhd_cost
                  ,@ItemlifoVovhdCost = itemlifo.vovhd_cost
                  ,@ItemlifoOutCost = itemlifo.out_cost
                  ,@ItemlifoUnitCost = itemlifo.unit_cost
                  from itemlifo WITH (UPDLOCK)
                  where itemlifo.item = @ItemlocItem
                     and itemlifo.inv_acct = @ItemlifoItemlocInvAcct
                     and itemlifo.lbr_acct = @ItemlifoItemlocLbrAcct
                     and itemlifo.fovhd_acct = @ItemlifoItemlocFovhdAcct
                     and itemlifo.vovhd_acct = @ItemlifoItemlocVovhdAcct
                     and itemlifo.out_acct = @ItemlifoItemlocOutAcct
                     and ISNULL(itemlifo.whse, '') = CASE @CostItemAtWhse WHEN 1 THEN @CoitemWhse ELSE '' END
                  order by itemlifo.trans_date asc
                  if @@rowcount <> 1
                     set @ItemlifoRowPointer = null
               end
               else
               begin
                  select top 1
                   @ItemlifoRowPointer = itemlifo.RowPointer
                  ,@ItemlifoItem = itemlifo.item
                  ,@ItemlifoInvAcct = itemlifo.inv_acct
                  ,@ItemlifoInvAcctUnit1 = itemlifo.inv_acct_unit1
                  ,@ItemlifoInvAcctUnit2 = itemlifo.inv_acct_unit2
                  ,@ItemlifoInvAcctUnit3 = itemlifo.inv_acct_unit3
                  ,@ItemlifoInvAcctUnit4 = itemlifo.inv_acct_unit4
                  ,@ItemlifoLbrAcct = itemlifo.lbr_acct
                  ,@ItemlifoLbrAcctUnit1 = itemlifo.lbr_acct_unit1
                  ,@ItemlifoLbrAcctUnit2 = itemlifo.lbr_acct_unit2
                  ,@ItemlifoLbrAcctUnit3 = itemlifo.lbr_acct_unit3
                  ,@ItemlifoLbrAcctUnit4 = itemlifo.lbr_acct_unit4
                  ,@ItemlifoFovhdAcct = itemlifo.fovhd_acct
                  ,@ItemlifoFovhdAcctUnit1 = itemlifo.fovhd_acct_unit1
                  ,@ItemlifoFovhdAcctUnit2 = itemlifo.fovhd_acct_unit2
                  ,@ItemlifoFovhdAcctUnit3 = itemlifo.fovhd_acct_unit3
                  ,@ItemlifoFovhdAcctUnit4 = itemlifo.fovhd_acct_unit4
                  ,@ItemlifoVovhdAcct = itemlifo.vovhd_acct
                  ,@ItemlifoVovhdAcctUnit1 = itemlifo.vovhd_acct_unit1
                  ,@ItemlifoVovhdAcctUnit2 = itemlifo.vovhd_acct_unit2
                  ,@ItemlifoVovhdAcctUnit3 = itemlifo.vovhd_acct_unit3
                  ,@ItemlifoVovhdAcctUnit4 = itemlifo.vovhd_acct_unit4
                  ,@ItemlifoOutAcct = itemlifo.out_acct
                  ,@ItemlifoOutAcctUnit1 = itemlifo.out_acct_unit1
                  ,@ItemlifoOutAcctUnit2 = itemlifo.out_acct_unit2
                  ,@ItemlifoOutAcctUnit3 = itemlifo.out_acct_unit3
                  ,@ItemlifoOutAcctUnit4 = itemlifo.out_acct_unit4
                  ,@ItemlifoTransDate = itemlifo.trans_date
                  ,@ItemlifoQty = itemlifo.qty
                  ,@ItemlifoLbrCost = itemlifo.lbr_cost
                  ,@ItemlifoMatlCost = itemlifo.matl_cost
                  ,@ItemlifoFovhdCost = itemlifo.fovhd_cost
                  ,@ItemlifoVovhdCost = itemlifo.vovhd_cost
                  ,@ItemlifoOutCost = itemlifo.out_cost
                  ,@ItemlifoUnitCost = itemlifo.unit_cost
                  from itemlifo WITH (UPDLOCK)
                  where itemlifo.item = @ItemlocItem
                     and itemlifo.inv_acct = @ItemlifoItemlocInvAcct
                     and itemlifo.lbr_acct = @ItemlifoItemlocLbrAcct
                     and itemlifo.fovhd_acct = @ItemlifoItemlocFovhdAcct
                     and itemlifo.vovhd_acct = @ItemlifoItemlocVovhdAcct
                     and itemlifo.out_acct = @ItemlifoItemlocOutAcct
                     and ISNULL(itemlifo.whse, '') = CASE @CostItemAtWhse WHEN 1 THEN @CoitemWhse ELSE '' END
                  order by itemlifo.trans_date desc
                  if @@rowcount <> 1
                     set @ItemlifoRowPointer = null
               end

               if @ItemlifoRowPointer is null
               BEGIN
                  /* Create negative */
                  set @ItemlifoRowPointer = newid()
                  SET @ItemlifoItem       = @ItemlocItem
                  SET @ItemlifoInvAcct   = @ItemlifoItemlocInvAcct
                  SET @ItemlifoInvAcctUnit1   = @ItemlifoItemlocInvAcctUnit1
                  SET @ItemlifoInvAcctUnit2   = @ItemlifoItemlocInvAcctUnit2
                  SET @ItemlifoInvAcctUnit3   = @ItemlifoItemlocInvAcctUnit3
                  SET @ItemlifoInvAcctUnit4   = @ItemlifoItemlocInvAcctUnit4
                  SET @ItemlifoLbrAcct   = @ItemlifoItemlocLbrAcct
                  SET @ItemlifoLbrAcctUnit1   = @ItemlifoItemlocLbrAcctUnit1
                  SET @ItemlifoLbrAcctUnit2   = @ItemlifoItemlocLbrAcctUnit2
                  SET @ItemlifoLbrAcctUnit3   = @ItemlifoItemlocLbrAcctUnit3
                  SET @ItemlifoLbrAcctUnit4   = @ItemlifoItemlocLbrAcctUnit4
                  SET @ItemlifoFovhdAcct = @ItemlifoItemlocFovhdAcct
                  SET @ItemlifoFovhdAcctUnit1 = @ItemlifoItemlocFovhdAcctUnit1
                  SET @ItemlifoFovhdAcctUnit2 = @ItemlifoItemlocFovhdAcctUnit2
                  SET @ItemlifoFovhdAcctUnit3 = @ItemlifoItemlocFovhdAcctUnit3
                  SET @ItemlifoFovhdAcctUnit4 = @ItemlifoItemlocFovhdAcctUnit4
                  SET @ItemlifoVovhdAcct = @ItemlifoItemlocVovhdAcct
                  SET @ItemlifoVovhdAcctUnit1 = @ItemlifoItemlocVovhdAcctUnit1
                  SET @ItemlifoVovhdAcctUnit2 = @ItemlifoItemlocVovhdAcctUnit2
                  SET @ItemlifoVovhdAcctUnit3 = @ItemlifoItemlocVovhdAcctUnit3
                  SET @ItemlifoVovhdAcctUnit4 = @ItemlifoItemlocVovhdAcctUnit4
                  SET @ItemlifoOutAcct   = @ItemlifoItemlocOutAcct
                  SET @ItemlifoOutAcctUnit1   = @ItemlifoItemlocOutAcctUnit1
                  SET @ItemlifoOutAcctUnit2   = @ItemlifoItemlocOutAcctUnit2
                  SET @ItemlifoOutAcctUnit3   = @ItemlifoItemlocOutAcctUnit3
                  SET @ItemlifoOutAcctUnit4   = @ItemlifoItemlocOutAcctUnit4
                  SET @ItemlifoTransDate = @STransDate
                  SET @ItemlifoQty        = 0

                  SET @ItemlifoLbrCost   = @ItemLbrCost
                  SET @ItemlifoMatlCost  = @ItemMatlCost
                  SET @ItemlifoFovhdCost = @ItemFovhdCost
                  SET @ItemlifoVovhdCost = @ItemVovhdCost
                  SET @ItemlifoOutCost   = @ItemOutCost
                  SET @ItemlifoUnitCost = @ItemlifoLbrCost + @ItemlifoMatlCost + @ItemlifoFovhdCost + @ItemlifoVovhdCost + @ItemlifoOutCost

                  insert into itemlifo (RowPointer, item
                  , inv_acct, inv_acct_unit1, inv_acct_unit2, inv_acct_unit3, inv_acct_unit4
                  , lbr_acct, lbr_acct_unit1, lbr_acct_unit2, lbr_acct_unit3, lbr_acct_unit4
                  , fovhd_acct, fovhd_acct_unit1, fovhd_acct_unit2, fovhd_acct_unit3, fovhd_acct_unit4
                  , vovhd_acct, vovhd_acct_unit1, vovhd_acct_unit2, vovhd_acct_unit3, vovhd_acct_unit4
                  , out_acct, out_acct_unit1, out_acct_unit2, out_acct_unit3, out_acct_unit4
                  , trans_date, qty, lbr_cost, matl_cost, fovhd_cost, vovhd_cost, out_cost, unit_cost
                  , whse)
                  values(@ItemlifoRowPointer, @ItemlifoItem
                  , @ItemlifoInvAcct, @ItemlifoInvAcctUnit1, @ItemlifoInvAcctUnit2, @ItemlifoInvAcctUnit3, @ItemlifoInvAcctUnit4
                  , @ItemlifoLbrAcct, @ItemlifoLbrAcctUnit1, @ItemlifoLbrAcctUnit2, @ItemlifoLbrAcctUnit3, @ItemlifoLbrAcctUnit4
                  , @ItemlifoFovhdAcct, @ItemlifoFovhdAcctUnit1, @ItemlifoFovhdAcctUnit2, @ItemlifoFovhdAcctUnit3, @ItemlifoFovhdAcctUnit4
                  , @ItemlifoVovhdAcct, @ItemlifoVovhdAcctUnit1, @ItemlifoVovhdAcctUnit2, @ItemlifoVovhdAcctUnit3, @ItemlifoVovhdAcctUnit4
                  , @ItemlifoOutAcct, @ItemlifoOutAcctUnit1, @ItemlifoOutAcctUnit2, @ItemlifoOutAcctUnit3, @ItemlifoOutAcctUnit4
                  , @ItemlifoTransDate, @ItemlifoQty, @ItemlifoLbrCost, @ItemlifoMatlCost, @ItemlifoFovhdCost, @ItemlifoVovhdCost, @ItemlifoOutCost, @ItemlifoUnitCost
                  , CASE @CostItemAtWhse WHEN 1 THEN @CoitemWhse ELSE NULL End )
               end

               if @ItemCostType = 'A'
               BEGIN
                  SET @ItemLbrCost   = @ItemlifoLbrCost
                  SET @ItemMatlCost  = @ItemlifoMatlCost
                  SET @ItemFovhdCost = @ItemlifoFovhdCost
                  SET @ItemVovhdCost = @ItemlifoVovhdCost
                  SET @ItemOutCost   = @ItemlifoOutCost
                  SET @ItemUnitCost  = @ItemLbrCost + @ItemMatlCost + @ItemFovhdCost + @ItemVovhdCost + @ItemOutCost

                  IF @CostItemAtWhse = 1
                     UPDATE itemwhse
                     SET
                        itemwhse.unit_cost  = @ItemUnitCost,
                        itemwhse.matl_cost  = @ItemMatlCost,
                        itemwhse.lbr_cost   = @ItemLbrCost,
                        itemwhse.fovhd_cost = @ItemFovhdCost,
                        itemwhse.vovhd_cost = @ItemVovhdCost,
                        itemwhse.out_cost   = @ItemOutCost
                     WHERE itemwhse.RowPointer = @ItemwhseRowPointer
                  ELSE
                     update item
                     set
                      lbr_cost = @ItemLbrCost
                     ,matl_cost = @ItemMatlCost
                     ,fovhd_cost = @ItemFovhdCost
                     ,vovhd_cost = @ItemVovhdCost
                     ,out_cost = @ItemOutCost
                     ,unit_cost = @ItemUnitCost
                     where RowPointer = @ItemRowPointer

               END

               SET @TNewCostLbr   = @ItemlifoLbrCost
               SET @TNewCostMatl  = @ItemlifoMatlCost
               SET @TNewCostFovhd = @ItemlifoFovhdCost
               SET @TNewCostVovhd = @ItemlifoVovhdCost
               SET @TNewCostOut   = @ItemlifoOutCost

               if @ItemlifoQty <= 0 or @SQtyRem < @ItemlifoQty
               BEGIN
                  SET @SQtyMove = @SQtyRem
                  SET @ItemlifoQty = @ItemlifoQty - @SQtyMove

                  update itemlifo
                  set
                   qty = @ItemlifoQty
                  where RowPointer = @ItemlifoRowPointer
               END
               else
               BEGIN
                  SET @SQtyMove = @ItemlifoQty

                  delete itemlifo where itemlifo.RowPointer = @ItemlifoRowPointer
                  set @ItemlifoRowPointer = null
               end

               SET @TTotPostLbr   = @TTotPostLbr   + @SQtyMove * @TNewCostLbr
               SET @TTotPostMatl  = @TTotPostMatl  + @SQtyMove * @TNewCostMatl
               SET @TTotPostFovhd = @TTotPostFovhd + @SQtyMove * @TNewCostFovhd
               SET @TTotPostVovhd = @TTotPostVovhd + @SQtyMove * @TNewCostVovhd
               SET @TTotPostOut   = @TTotPostOut   + @SQtyMove * @TNewCostOut
               SET @SQtyRem = @SQtyRem - @SQtyMove
            end

            /* Flip sign for negative adjust */
            SET @TTotPostLbr   = - @TTotPostLbr
            SET @TTotPostMatl  = - @TTotPostMatl
            SET @TTotPostFovhd = - @TTotPostFovhd
            SET @TTotPostVovhd = - @TTotPostVovhd
            SET @TTotPostOut   = - @TTotPostOut

            /* RESET item.unit-cost AND itemprice.unit-price1
               IN CASE LEVEL CHANGED */
            EXEC dbo.ResetUcSp
                 @Item      = @SItem
               , @Whse      = @CoitemWhse
               , @Lot       = @SLot
               , @Loc       = @SLoc
               , @MatlCost  = 0
               , @LbrCost   = 0
               , @FovhdCost = 0
               , @VovhdCost = 0
               , @OutCost   = 0
               , @Qty       = -1
               , @UnitCost  = 0
               , @Infobar   = @Infobar OUTPUT

         end
         else if @ItemCostMethod = 'S'
         BEGIN
            if @ItemLotTracked <> 0
            BEGIN
               SET @TTotPostLbr   = @TAdjQty * @LotLocLbrCost
               SET @TTotPostMatl  = @TAdjQty * @LotLocMatlCost
               SET @TTotPostFovhd = @TAdjQty * @LotLocFovhdCost
               SET @TTotPostVovhd = @TAdjQty * @LotLocVovhdCost
               SET @TTotPostOut   = @TAdjQty * @LotLocOutCost
            END
            else
            BEGIN
               SET @TTotPostLbr   = @TAdjQty * @ItemlocLbrCost
               SET @TTotPostMatl  = @TAdjQty * @ItemlocMatlCost
               SET @TTotPostFovhd = @TAdjQty * @ItemlocFovhdCost
               SET @TTotPostVovhd = @TAdjQty * @ItemlocVovhdCost
               SET @TTotPostOut   = @TAdjQty * @ItemlocOutCost
            END
         end

         /* Std Cost:  Override above t-tot-post calculation */
         if @ItemCostType = 'S'
         BEGIN
            SET @TTotPostLbr   = @TAdjQty * @ItemLbrCost
            SET @TTotPostMatl  = @TAdjQty * @ItemMatlCost
            SET @TTotPostFovhd = @TAdjQty * @ItemFovhdCost
            SET @TTotPostVovhd = @TAdjQty * @ItemVovhdCost
            SET @TTotPostOut   = @TAdjQty * @ItemOutCost
         END

         SET @CoitemCgsTotalLbr   = @CoitemCgsTotalLbr   - round(@TTotPostLbr, @TDomPlaces)
         SET @CoitemCgsTotalMatl  = @CoitemCgsTotalMatl  - round(@TTotPostMatl, @TDomPlaces)
         SET @CoitemCgsTotalFovhd = @CoitemCgsTotalFovhd - round(@TTotPostFovhd, @TDomPlaces)
         SET @CoitemCgsTotalVovhd = @CoitemCgsTotalVovhd - round(@TTotPostVovhd, @TDomPlaces)
         SET @CoitemCgsTotalOut   = @CoitemCgsTotalOut   - round(@TTotPostOut, @TDomPlaces)

         SET @CoitemCgsTotal = @CoitemCgsTotalLbr + @CoitemCgsTotalMatl + @CoitemCgsTotalFovhd + @CoitemCgsTotalVovhd + @CoitemCgsTotalOut

         SET @MatltranLbrCost   = round(@TTotPostLbr   / @TAdjQty, @XCurrencyPlacesCp)
         SET @MatltranMatlCost  = round(@TTotPostMatl  / @TAdjQty, @XCurrencyPlacesCp)
         SET @MatltranFovhdCost = round(@TTotPostFovhd / @TAdjQty, @XCurrencyPlacesCp)
         SET @MatltranVovhdCost = round(@TTotPostVovhd / @TAdjQty, @XCurrencyPlacesCp)
         SET @MatltranOutCost   = round(@TTotPostOut   / @TAdjQty, @XCurrencyPlacesCp)

         SET @MatltranCost = @MatltranLbrCost + @MatltranMatlCost + @MatltranFovhdCost + @MatltranVovhdCost + @MatltranOutCost

         if (@CoShipRowPointer is not null)
         BEGIN
            SET @CoShipLbrCost   = @MatltranLbrCost
            SET @CoShipMatlCost  = @MatltranMatlCost
            SET @CoShipFovhdCost = @MatltranFovhdCost
            SET @CoShipVovhdCost = @MatltranVovhdCost
            SET @CoShipOutCost   = @MatltranOutCost

            SET @CoShipCost       = @CoShipLbrCost + @CoShipMatlCost + @CoShipFovhdCost + @CoShipVovhdCost + @CoShipOutCost

            set @AvgMatlCost = @CoShipMatlCost
            set @AvgLbrCost = @CoShipLbrCost
            set @AvgFovhdCost = @CoShipFovhdCost
            set @AvgVovhdCost = @CoShipVovhdCost
            set @AvgOutCost = @CoShipOutCost

            update co_ship
            set
             lbr_cost = @CoShipLbrCost
            ,matl_cost = @CoShipMatlCost
            ,fovhd_cost = @CoShipFovhdCost
            ,vovhd_cost = @CoShipVovhdCost
            ,out_cost = @CoShipOutCost
            ,cost = @CoShipCost
            where RowPointer = @CoShipRowPointer
         END
      end
      else
      BEGIN
         /* RETURN AT AVERAGE COST OF SHIPMENTS, t-adj-qty > 0 */
         if CHARINDEX( 'R', @ItemwhseCycleType) <> 0
            SET @ItemwhseCycleFlag = 1

         /* For shipping returns of lot tracked items using Actual/Specific costing,
            attempt to return at the cost originally shipped at */
         SET @UseOriginalLotCost = 0

         if @ItemLotTracked <> 0 AND @ItemCostMethod = 'S' AND @ItemCostType = 'A'
         BEGIN
            SET @OrigMatlRowPointer = NULL
            SELECT TOP 1
              @OrigMatlRowPointer = omatl.RowPointer
            , @OrigMatlCost      = omatl.cost
            , @OrigMatlMatlCost  = omatl.matl_cost
            , @OrigMatlLbrCost   = omatl.lbr_cost
            , @OrigMatlFovhdCost = omatl.fovhd_cost
            , @OrigMatlVovhdCost = omatl.vovhd_cost
            , @OrigMatlOutCost   = omatl.out_cost
            FROM matltran AS omatl
            WHERE omatl.trans_type = 'S' AND
                  omatl.qty < 0 AND
                  omatl.item = @MatltranItem AND
                  omatl.loc = @MatltranLoc AND
                  omatl.lot = @MatltranLot AND
                  omatl.ref_type = @MatltranRefType AND
                  omatl.ref_num =  @MatltranRefNum AND
                  omatl.ref_line_suf = @MatltranRefLineSuf AND
                  omatl.ref_release = @MatltranRefRelease

            IF @OrigMatlRowPointer IS NOT NULL AND
               /* All shipments for this CO and lot must have the same cost.  Otherwise, revert to normal logic */
               NOT EXISTS (SELECT TOP 1 * FROM matltran AS matl2
               WHERE matl2.RowPointer <> @OrigMatlRowPointer AND
                     matl2.trans_type = 'S' AND
                     matl2.qty < 0 AND
                     matl2.item = @MatltranItem AND
                     matl2.loc = @MatltranLoc AND
                     matl2.lot = @MatltranLot AND
                     matl2.ref_type = @MatltranRefType AND
                     matl2.ref_num =  @MatltranRefNum AND
                     matl2.ref_line_suf = @MatltranRefLineSuf AND
                     matl2.ref_release = @MatltranRefRelease AND
                     matl2.cost <> @OrigMatlCost)

               SET @UseOriginalLotCost = 1

         END /* lot tracked shipments */

         SET @MatltranLbrCost   = CASE WHEN @UseOriginalLotCost = 1 THEN @OrigMatlLbrCost ELSE
                                     round(@AvgLbrCost, @XCurrencyPlacesCp) END
         SET @MatltranMatlCost  = CASE WHEN @UseOriginalLotCost = 1 THEN @OrigMatlMatlCost ELSE
                                     round(@AvgMatlCost, @XCurrencyPlacesCp) END
         SET @MatltranFovhdCost = CASE WHEN @UseOriginalLotCost = 1 THEN @OrigMatlFovhdCost ELSE
                                     round(@AvgFovhdCost, @XCurrencyPlacesCp) END
         SET @MatltranVovhdCost = CASE WHEN @UseOriginalLotCost = 1 THEN @OrigMatlVovhdCost ELSE
                                     round(@AvgVovhdCost, @XCurrencyPlacesCp) END
         SET @MatltranOutCost   = CASE WHEN @UseOriginalLotCost = 1 THEN @OrigMatlOutCost ELSE
                                     round(@AvgOutCost, @XCurrencyPlacesCp) END

         SET @MatltranCost       = @MatltranLbrCost + @MatltranMatlCost + @MatltranFovhdCost + @MatltranVovhdCost + @MatltranOutCost

         if (@CoShipRowPointer is not null)
         BEGIN
            SET @CoShipLbrCost   = @MatltranLbrCost
            SET @CoShipMatlCost  = @MatltranMatlCost
            SET @CoShipFovhdCost = @MatltranFovhdCost
            SET @CoShipVovhdCost = @MatltranVovhdCost
            SET @CoShipOutCost   = @MatltranOutCost

            SET @CoShipCost       = @CoShipLbrCost + @CoShipMatlCost + @CoShipFovhdCost + @CoShipVovhdCost + @CoShipOutCost

            update co_ship
            set
             lbr_cost = @CoShipLbrCost
            ,matl_cost = @CoShipMatlCost
            ,fovhd_cost = @CoShipFovhdCost
            ,vovhd_cost = @CoShipVovhdCost
            ,out_cost = @CoShipOutCost
            ,cost = @CoShipCost
            where RowPointer = @CoShipRowPointer
         END

         if @ItemCostMethod = 'A'
         BEGIN
            SET @TTotPostLbr   = round(@TAdjQty * @ItemLbrCost, @TDomPlaces)
            SET @TTotPostMatl  = round(@TAdjQty * @ItemMatlCost, @TDomPlaces)
            SET @TTotPostFovhd = round(@TAdjQty * @ItemFovhdCost, @TDomPlaces)
            SET @TTotPostVovhd = round(@TAdjQty * @ItemVovhdCost, @TDomPlaces)
            SET @TTotPostOut   = round(@TAdjQty * @ItemOutCost, @TDomPlaces)

            SET @TAdjPostLbr   = @TAdjQty * @MatltranLbrCost - @TTotPostLbr
            SET @TAdjPostMatl  = @TAdjQty * @MatltranMatlCost - @TTotPostMatl
            SET @TAdjPostFovhd = @TAdjQty * @MatltranFovhdCost - @TTotPostFovhd
            SET @TAdjPostVovhd = @TAdjQty * @MatltranVovhdCost - @TTotPostVovhd
            SET @TAdjPostOut   = @TAdjQty * @MatltranOutCost - @TTotPostOut
         END
         else if CHARINDEX( @ItemCostMethod, 'LF') <> 0
         BEGIN
            /* LIFO or FIFO Costing */
            SET @SQtyMove = @TAdjQty

            SET @TTotPostLbr   = round(@TAdjQty * @MatltranLbrCost, @TDomPlaces)
            SET @TTotPostMatl  = round(@TAdjQty * @MatltranMatlCost, @TDomPlaces)
            SET @TTotPostFovhd = round(@TAdjQty * @MatltranFovhdCost, @TDomPlaces)
            SET @TTotPostVovhd = round(@TAdjQty * @MatltranVovhdCost, @TDomPlaces)
            SET @TTotPostOut   = round(@TAdjQty * @MatltranOutCost, @TDomPlaces)

            select top 1
             @ItemlifoRowPointer = itemlifo.RowPointer
            ,@ItemlifoItem = itemlifo.item
            ,@ItemlifoInvAcct = itemlifo.inv_acct
            ,@ItemlifoInvAcctUnit1 = itemlifo.inv_acct_unit1
            ,@ItemlifoInvAcctUnit2 = itemlifo.inv_acct_unit2
            ,@ItemlifoInvAcctUnit3 = itemlifo.inv_acct_unit3
            ,@ItemlifoInvAcctUnit4 = itemlifo.inv_acct_unit4
            ,@ItemlifoLbrAcct = itemlifo.lbr_acct
            ,@ItemlifoLbrAcctUnit1 = itemlifo.lbr_acct_unit1
            ,@ItemlifoLbrAcctUnit2 = itemlifo.lbr_acct_unit2
            ,@ItemlifoLbrAcctUnit3 = itemlifo.lbr_acct_unit3
            ,@ItemlifoLbrAcctUnit4 = itemlifo.lbr_acct_unit4
            ,@ItemlifoFovhdAcct = itemlifo.fovhd_acct
            ,@ItemlifoFovhdAcctUnit1 = itemlifo.fovhd_acct_unit1
            ,@ItemlifoFovhdAcctUnit2 = itemlifo.fovhd_acct_unit2
            ,@ItemlifoFovhdAcctUnit3 = itemlifo.fovhd_acct_unit3
            ,@ItemlifoFovhdAcctUnit4 = itemlifo.fovhd_acct_unit4
            ,@ItemlifoVovhdAcct = itemlifo.vovhd_acct
            ,@ItemlifoVovhdAcctUnit1 = itemlifo.vovhd_acct_unit1
            ,@ItemlifoVovhdAcctUnit2 = itemlifo.vovhd_acct_unit2
            ,@ItemlifoVovhdAcctUnit3 = itemlifo.vovhd_acct_unit3
            ,@ItemlifoVovhdAcctUnit4 = itemlifo.vovhd_acct_unit4
            ,@ItemlifoOutAcct = itemlifo.out_acct
            ,@ItemlifoOutAcctUnit1 = itemlifo.out_acct_unit1
            ,@ItemlifoOutAcctUnit2 = itemlifo.out_acct_unit2
            ,@ItemlifoOutAcctUnit3 = itemlifo.out_acct_unit3
            ,@ItemlifoOutAcctUnit4 = itemlifo.out_acct_unit4
            ,@ItemlifoTransDate = itemlifo.trans_date
            ,@ItemlifoQty = itemlifo.qty
            ,@ItemlifoLbrCost = itemlifo.lbr_cost
            ,@ItemlifoMatlCost = itemlifo.matl_cost
            ,@ItemlifoFovhdCost = itemlifo.fovhd_cost
            ,@ItemlifoVovhdCost = itemlifo.vovhd_cost
            ,@ItemlifoOutCost = itemlifo.out_cost
            ,@ItemlifoUnitCost = itemlifo.unit_cost
            from itemlifo WITH (UPDLOCK)
            where itemlifo.item = @ItemlocItem
               and itemlifo.inv_acct = @ItemlifoItemlocInvAcct
               and itemlifo.lbr_acct = @ItemlifoItemlocLbrAcct
               and itemlifo.fovhd_acct = @ItemlifoItemlocFovhdAcct
               and itemlifo.vovhd_acct = @ItemlifoItemlocVovhdAcct
               and itemlifo.out_acct = @ItemlifoItemlocOutAcct
               and itemlifo.qty <= 0
               and ISNULL(itemlifo.whse, '') = CASE @CostItemAtWhse WHEN 1 THEN @CoitemWhse ELSE '' END
            order by itemlifo.trans_date asc
            if @@rowcount <> 1
               set @ItemlifoRowPointer = null

            if (@ItemlifoRowPointer is not null)
            BEGIN
               SET @TOldCostLbr   = @ItemlifoLbrCost
               SET @TOldCostMatl  = @ItemlifoMatlCost
               SET @TOldCostFovhd = @ItemlifoFovhdCost
               SET @TOldCostVovhd = @ItemlifoVovhdCost
               SET @TOldCostOut   = @ItemlifoOutCost

               if @SQtyMove < - @ItemlifoQty
               BEGIN
                  SET @SQtyAdj = @SQtyMove
                  SET @ItemlifoQty = @ItemlifoQty + @SQtyMove

                  update itemlifo
                  set
                   qty = @ItemlifoQty
                  where RowPointer = @ItemlifoRowPointer
               END
               else
               BEGIN
                  SET @SQtyAdj = - @ItemlifoQty

                  delete itemlifo where itemlifo.RowPointer = @ItemlifoRowPointer
                  set @ItemlifoRowPointer = null
               end

               /* Different from normal */
               SET @TAdjPostLbr   = (@MatltranLbrCost - @TOldCostLbr) * @SQtyAdj
               SET @TAdjPostMatl  = (@MatltranMatlCost - @TOldCostMatl) * @SQtyAdj
               SET @TAdjPostFovhd = (@MatltranFovhdCost - @TOldCostFovhd) * @SQtyAdj
               SET @TAdjPostVovhd = (@MatltranVovhdCost - @TOldCostVovhd) * @SQtyAdj
               SET @TAdjPostOut   = (@MatltranOutCost - @TOldCostOut) * @SQtyAdj

               SET @TTotPostLbr   = @TTotPostLbr   - @TAdjPostLbr
               SET @TTotPostMatl  = @TTotPostMatl  - @TAdjPostMatl
               SET @TTotPostFovhd = @TTotPostFovhd - @TAdjPostFovhd
               SET @TTotPostVovhd = @TTotPostVovhd - @TAdjPostVovhd
               SET @TTotPostOut   = @TTotPostOut   - @TAdjPostOut

               SET @SQtyMove = @SQtyMove - @SQtyAdj
            end
            if @ItemlifoRowPointer is null
               SET @ItemlifoNewFlag = 1

            if @SQtyMove > 0
            BEGIN
               set @ItemlifoRowPointer = newid()
               SET @ItemlifoItem       = @ItemlocItem
               SET @ItemlifoInvAcct   = @ItemlifoItemlocInvAcct
               SET @ItemlifoInvAcctUnit1   = @ItemlifoItemlocInvAcctUnit1
               SET @ItemlifoInvAcctUnit2   = @ItemlifoItemlocInvAcctUnit2
               SET @ItemlifoInvAcctUnit3   = @ItemlifoItemlocInvAcctUnit3
               SET @ItemlifoInvAcctUnit4   = @ItemlifoItemlocInvAcctUnit4
               SET @ItemlifoLbrAcct   = @ItemlifoItemlocLbrAcct
               SET @ItemlifoLbrAcctUnit1   = @ItemlifoItemlocLbrAcctUnit1
               SET @ItemlifoLbrAcctUnit2   = @ItemlifoItemlocLbrAcctUnit2
               SET @ItemlifoLbrAcctUnit3   = @ItemlifoItemlocLbrAcctUnit3
               SET @ItemlifoLbrAcctUnit4   = @ItemlifoItemlocLbrAcctUnit4
               SET @ItemlifoFovhdAcct = @ItemlifoItemlocFovhdAcct
               SET @ItemlifoFovhdAcctUnit1 = @ItemlifoItemlocFovhdAcctUnit1
               SET @ItemlifoFovhdAcctUnit2 = @ItemlifoItemlocFovhdAcctUnit2
               SET @ItemlifoFovhdAcctUnit3 = @ItemlifoItemlocFovhdAcctUnit3
               SET @ItemlifoFovhdAcctUnit4 = @ItemlifoItemlocFovhdAcctUnit4
               SET @ItemlifoVovhdAcct = @ItemlifoItemlocVovhdAcct
               SET @ItemlifoVovhdAcctUnit1 = @ItemlifoItemlocVovhdAcctUnit1
               SET @ItemlifoVovhdAcctUnit2 = @ItemlifoItemlocVovhdAcctUnit2
               SET @ItemlifoVovhdAcctUnit3 = @ItemlifoItemlocVovhdAcctUnit3
               SET @ItemlifoVovhdAcctUnit4 = @ItemlifoItemlocVovhdAcctUnit4
               SET @ItemlifoOutAcct   = @ItemlifoItemlocOutAcct
               SET @ItemlifoOutAcctUnit1   = @ItemlifoItemlocOutAcctUnit1
               SET @ItemlifoOutAcctUnit2   = @ItemlifoItemlocOutAcctUnit2
               SET @ItemlifoOutAcctUnit3   = @ItemlifoItemlocOutAcctUnit3
               SET @ItemlifoOutAcctUnit4   = @ItemlifoItemlocOutAcctUnit4
               SET @ItemlifoTransDate = @STransDate
               SET @ItemlifoQty        = @SQtyMove

               SET @ItemlifoLbrCost   = @MatltranLbrCost
               SET @ItemlifoMatlCost  = @MatltranMatlCost
               SET @ItemlifoFovhdCost = @MatltranFovhdCost
               SET @ItemlifoVovhdCost = @MatltranVovhdCost
               SET @ItemlifoOutCost   = @MatltranOutCost
               SET @ItemlifoUnitCost  = @ItemlifoLbrCost + @ItemlifoMatlCost + @ItemlifoFovhdCost + @ItemlifoVovhdCost + @ItemlifoOutCost

               while 1=1
               begin
                  if not exists(select 1 from itemlifo with (readuncommitted)
                  where item = @ItemlifoItem
                  and inv_acct = @ItemlifoInvAcct
                  and lbr_acct = @ItemlifoLbrAcct
                  and fovhd_acct = @ItemlifoFovhdAcct
                  and vovhd_acct = @ItemlifoVovhdAcct
                  and out_acct = @ItemlifoOutAcct
                  and trans_date = @ItemlifoTransDate
                  and ISNULL(itemlifo.whse, '') = CASE @CostItemAtWhse WHEN 1 THEN @CoitemWhse ELSE '' END)
                     break
                  set @NextTick = @ItemlifoTransDate
                  set @TimeIncrement = 3
                  while 1=1
                  begin
                     set @NextTick = dateadd(millisecond, @TimeIncrement, @NextTick)
                     if @NextTick != @ItemlifoTransDate
                        break
                     set @TimeIncrement = @TimeIncrement + 3
                  end
                  set @ItemlifoTransDate = @NextTick
               end

               insert into itemlifo (RowPointer, item
               , inv_acct, inv_acct_unit1, inv_acct_unit2, inv_acct_unit3, inv_acct_unit4
               , lbr_acct, lbr_acct_unit1, lbr_acct_unit2, lbr_acct_unit3, lbr_acct_unit4
               , fovhd_acct, fovhd_acct_unit1, fovhd_acct_unit2, fovhd_acct_unit3, fovhd_acct_unit4
               , vovhd_acct, vovhd_acct_unit1, vovhd_acct_unit2, vovhd_acct_unit3, vovhd_acct_unit4
               , out_acct, out_acct_unit1, out_acct_unit2, out_acct_unit3, out_acct_unit4
               , trans_date, qty, lbr_cost, matl_cost, fovhd_cost, vovhd_cost, out_cost, unit_cost
               , whse)
               values(@ItemlifoRowPointer, @ItemlifoItem
               , @ItemlifoInvAcct, @ItemlifoInvAcctUnit1, @ItemlifoInvAcctUnit2, @ItemlifoInvAcctUnit3, @ItemlifoInvAcctUnit4
               , @ItemlifoLbrAcct, @ItemlifoLbrAcctUnit1, @ItemlifoLbrAcctUnit2, @ItemlifoLbrAcctUnit3, @ItemlifoLbrAcctUnit4
               , @ItemlifoFovhdAcct, @ItemlifoFovhdAcctUnit1, @ItemlifoFovhdAcctUnit2, @ItemlifoFovhdAcctUnit3, @ItemlifoFovhdAcctUnit4
               , @ItemlifoVovhdAcct, @ItemlifoVovhdAcctUnit1, @ItemlifoVovhdAcctUnit2, @ItemlifoVovhdAcctUnit3, @ItemlifoVovhdAcctUnit4
               , @ItemlifoOutAcct, @ItemlifoOutAcctUnit1, @ItemlifoOutAcctUnit2, @ItemlifoOutAcctUnit3, @ItemlifoOutAcctUnit4
               , @ItemlifoTransDate, @ItemlifoQty, @ItemlifoLbrCost, @ItemlifoMatlCost, @ItemlifoFovhdCost, @ItemlifoVovhdCost, @ItemlifoOutCost, @ItemlifoUnitCost
               , CASE @CostItemAtWhse WHEN 1 THEN @CoitemWhse ELSE null End )

               if @ItemCostType = 'A' AND @ItemlifoNewFlag = 1
               BEGIN
                  IF @CostItemAtWhse = 1
                     UPDATE itemwhse
                     SET
                        itemwhse.unit_cost  = @ItemlifoUnitCost,
                        itemwhse.matl_cost  = @ItemlifoMatlCost,
                        itemwhse.lbr_cost   = @ItemlifoLbrCost,
                        itemwhse.fovhd_cost = @ItemlifoFovhdCost,
                        itemwhse.vovhd_cost = @ItemlifoVovhdCost,
                        itemwhse.out_cost   = @ItemlifoOutCost
                     WHERE itemwhse.RowPointer = @ItemwhseRowPointer
                  ELSE
                     update item
                     set
                      lbr_cost = @ItemlifoLbrCost
                     ,matl_cost = @ItemlifoMatlCost
                     ,fovhd_cost = @ItemlifoFovhdCost
                     ,vovhd_cost = @ItemlifoVovhdCost
                     ,out_cost = @ItemlifoOutCost
                     ,unit_cost = @ItemlifoUnitCost
                     where RowPointer = @ItemRowPointer

               END
            end
         end
         else if @ItemCostMethod = 'S'
         BEGIN
            if ((@LotLocRowPointer is not null)) and @ItemLotTracked <> 0
            BEGIN
               SET @TAdjPostLbr   = @LotLocQtyOnHand * (@LotLocLbrCost - @MatltranLbrCost)
               SET @TAdjPostMatl  = @LotLocQtyOnHand * (@LotLocMatlCost - @MatltranMatlCost)
               SET @TAdjPostFovhd = @LotLocQtyOnHand * (@LotLocFovhdCost - @MatltranFovhdCost)
               SET @TAdjPostVovhd = @LotLocQtyOnHand * (@LotLocVovhdCost - @MatltranVovhdCost)
               SET @TAdjPostOut   = @LotLocQtyOnHand * (@LotLocOutCost - @MatltranOutCost)
            END
            else
            BEGIN
               SET @TAdjPostLbr   = @ItemlocQtyOnHand * (@ItemlocLbrCost - @MatltranLbrCost)
               SET @TAdjPostMatl  = @ItemlocQtyOnHand * (@ItemlocMatlCost - @MatltranMatlCost)
               SET @TAdjPostFovhd = @ItemlocQtyOnHand * (@ItemlocFovhdCost - @MatltranFovhdCost)
               SET @TAdjPostVovhd = @ItemlocQtyOnHand * (@ItemlocVovhdCost - @MatltranVovhdCost)
               SET @TAdjPostOut   = @ItemlocQtyOnHand * (@ItemlocOutCost - @MatltranOutCost)
            END

            SET @TTotPostLbr   = round(@TAdjQty * @MatltranLbrCost - @TAdjPostLbr, @TDomPlaces)
            SET @TTotPostMatl  = round(@TAdjQty * @MatltranMatlCost - @TAdjPostMatl, @TDomPlaces)
            SET @TTotPostFovhd = round(@TAdjQty * @MatltranFovhdCost - @TAdjPostFovhd, @TDomPlaces)
            SET @TTotPostVovhd = round(@TAdjQty * @MatltranVovhdCost - @TAdjPostVovhd, @TDomPlaces)
            SET @TTotPostOut   = round(@TAdjQty * @MatltranOutCost - @TAdjPostOut, @TDomPlaces)

            IF @ItemLotTracked = 0
            BEGIN
               SET @ItemlocLbrCost   = @MatltranLbrCost
               SET @ItemlocMatlCost  = @MatltranMatlCost
               SET @ItemlocFovhdCost = @MatltranFovhdCost
               SET @ItemlocVovhdCost = @MatltranVovhdCost
               SET @ItemlocOutCost   = @MatltranOutCost
               SET @ItemlocUnitCost  = @ItemlocLbrCost + @ItemlocMatlCost + @ItemlocFovhdCost + @ItemlocVovhdCost + @ItemlocOutCost

               update itemloc
               set
                lbr_cost = @ItemlocLbrCost
               ,matl_cost = @ItemlocMatlCost
               ,fovhd_cost = @ItemlocFovhdCost
               ,vovhd_cost = @ItemlocVovhdCost
               ,out_cost = @ItemlocOutCost
               ,unit_cost = @ItemlocUnitCost
               where RowPointer = @ItemlocRowPointer
            END
            ELSE
            if (@LotLocRowPointer is not null)
            BEGIN
               SET @LotLocLbrCost   = @MatltranLbrCost
               SET @LotLocMatlCost  = @MatltranMatlCost
               SET @LotLocFovhdCost = @MatltranFovhdCost
               SET @LotLocVovhdCost = @MatltranVovhdCost
               SET @LotLocOutCost   = @MatltranOutCost
               SET @LotLocUnitCost  = @LotLocLbrCost + @LotLocMatlCost + @LotLocFovhdCost + @LotLocVovhdCost + @LotLocOutCost

               EXEC dbo.DefineVariableSp 'SkipItemLotLocPostSave', '1', @Infobar output

               update lot_loc
               set
                lbr_cost = @LotLocLbrCost
               ,matl_cost = @LotLocMatlCost
               ,fovhd_cost = @LotLocFovhdCost
               ,vovhd_cost = @LotLocVovhdCost
               ,out_cost = @LotLocOutCost
               ,unit_cost = @LotLocUnitCost
               where RowPointer = @LotLocRowPointer
            END

            if @ItemCostType = 'A'
            BEGIN
               SET @ItemLbrCost   = @MatltranLbrCost
               SET @ItemMatlCost  = @MatltranMatlCost
               SET @ItemFovhdCost = @MatltranFovhdCost
               SET @ItemVovhdCost = @MatltranVovhdCost
               SET @ItemOutCost   = @MatltranOutCost
               SET @ItemUnitCost  = @ItemLbrCost + @ItemMatlCost + @ItemFovhdCost + @ItemVovhdCost + @ItemOutCost

               IF @CostItemAtWhse = 1
                  UPDATE itemwhse
                  SET
                     itemwhse.unit_cost  = @ItemUnitCost,
                     itemwhse.matl_cost  = @ItemMatlCost,
                     itemwhse.lbr_cost   = @ItemLbrCost,
                     itemwhse.fovhd_cost = @ItemFovhdCost,
                     itemwhse.vovhd_cost = @ItemVovhdCost,
                     itemwhse.out_cost   = @ItemOutCost
                  WHERE itemwhse.RowPointer = @ItemwhseRowPointer
               ELSE
                  update item
                 set
                   lbr_cost = @ItemLbrCost
                  ,matl_cost = @ItemMatlCost
                  ,fovhd_cost = @ItemFovhdCost
                  ,vovhd_cost = @ItemVovhdCost
                  ,out_cost = @ItemOutCost
                  ,unit_cost = @ItemUnitCost
                  where RowPointer = @ItemRowPointer

               select top 1
                @XItempriceRowPointer = x_itemprice.RowPointer
               ,@XItempriceEffectDate = x_itemprice.effect_date
               from itemprice  as x_itemprice
               where x_itemprice.item = @ItemItem
                  and x_itemprice.effect_date <= dbo.GetSiteDate(GETDATE())
               order by x_itemprice.effect_date desc
               if @@rowcount <> 1
                  set @XItempriceRowPointer = null

               if (@XItempriceRowPointer is not null)
               begin
                  declare itemprice_crs cursor local static for
                  select
                   itemprice.curr_code
                  ,itemprice.unit_price1
                  ,itemprice.RowPointer
                  from itemprice WITH (UPDLOCK)
                  where itemprice.item = @ItemItem
                  and itemprice.effect_date >= @XItempriceEffectDate
                  AND itemprice.reprice <> 0

                  open itemprice_crs
                  while 1 = 1
                  begin
                     fetch itemprice_crs into
                      @ItempriceCurrCode
                     ,@ItempriceUnitPrice1
                     ,@ItempriceRowPointer
                     if @@fetch_status <> 0
                        break

                     SET @TRate = @CoExchRate
                     DECLARE @CurrCnvtAmount1 AmountType
                     SET @CurrCnvtAmount1 = @ItemUnitCost * @ProdcodeMarkup

                     EXEC @Severity = dbo.CurrCnvtSp
                          @CurrCode =     @ItempriceCurrCode
                        , @FromDomestic = 1
                        , @UseBuyRate =   0
                        , @RoundResult =  0
                        , @Date =         @CoOrderDate
                        , @TRate =        @TRate  OUTPUT
                        , @Infobar =      @Infobar OUTPUT
                        , @Amount1 =      @CurrCnvtAmount1
                        , @Result1 =      @ItempriceUnitPrice1 OUTPUT
                        , @Site = @ParmsSite
                        , @DomCurrCode = @CurrparmsCurrCode

                     IF (@Severity >= 5)
                        GOTO EOF

                     update itemprice
                     set
                      unit_price1 = @ItempriceUnitPrice1
                     where RowPointer = @ItempriceRowPointer
                  end
                  close itemprice_crs
                  deallocate itemprice_crs
               end
            end
         end
         else if @ItemCostMethod = 'C'
         BEGIN
            /* Standard Costing */
            SET @TTotPostLbr   = round(@TAdjQty * @ItemLbrCost, @TDomPlaces)
            SET @TTotPostMatl  = round(@TAdjQty * @ItemMatlCost, @TDomPlaces)
            SET @TTotPostFovhd = round(@TAdjQty * @ItemFovhdCost, @TDomPlaces)
            SET @TTotPostVovhd = round(@TAdjQty * @ItemVovhdCost, @TDomPlaces)
            SET @TTotPostOut   = round(@TAdjQty * @ItemOutCost, @TDomPlaces)

            SET @TAdjPostLbr   = @TAdjQty * @MatltranLbrCost   - @TTotPostLbr
            SET @TAdjPostMatl  = @TAdjQty * @MatltranMatlCost  - @TTotPostMatl
            SET @TAdjPostFovhd = @TAdjQty * @MatltranFovhdCost - @TTotPostFovhd
            SET @TAdjPostVovhd = @TAdjQty * @MatltranVovhdCost - @TTotPostVovhd
            SET @TAdjPostOut   = @TAdjQty * @MatltranOutCost   - @TTotPostOut
         END

         if @ItemCostType = 'S'
         BEGIN
            SET @TTotPostLbr   = round(@TAdjQty * @ItemLbrCost, @TDomPlaces)
            SET @TTotPostMatl  = round(@TAdjQty * @ItemMatlCost, @TDomPlaces)
            SET @TTotPostFovhd = round(@TAdjQty * @ItemFovhdCost, @TDomPlaces)
            SET @TTotPostVovhd = round(@TAdjQty * @ItemVovhdCost, @TDomPlaces)
            SET @TTotPostOut   = round(@TAdjQty * @ItemOutCost, @TDomPlaces)

            SET @TAdjPostLbr   = @TAdjQty * @MatltranLbrCost   - @TTotPostLbr
            SET @TAdjPostMatl  = @TAdjQty * @MatltranMatlCost  - @TTotPostMatl
            SET @TAdjPostFovhd = @TAdjQty * @MatltranFovhdCost - @TTotPostFovhd
            SET @TAdjPostVovhd = @TAdjQty * @MatltranVovhdCost - @TTotPostVovhd
            SET @TAdjPostOut   = @TAdjQty * @MatltranOutCost   - @TTotPostOut
         END

         SET @CoitemCgsTotalLbr  = @CoitemCgsTotalLbr   - (@TTotPostLbr + @TAdjPostLbr)
         SET @CoitemCgsTotalMatl  = @CoitemCgsTotalMatl  - (@TTotPostMatl + @TAdjPostMatl)
         SET @CoitemCgsTotalFovhd = @CoitemCgsTotalFovhd - (@TTotPostFovhd + @TAdjPostFovhd)
         SET @CoitemCgsTotalVovhd = @CoitemCgsTotalVovhd - (@TTotPostVovhd + @TAdjPostVovhd)
         SET @CoitemCgsTotalOut   = @CoitemCgsTotalOut   - (@TTotPostOut + @TAdjPostOut)
         SET @CoitemCgsTotal = @CoitemCgsTotalLbr + @CoitemCgsTotalMatl + @CoitemCgsTotalFovhd + @CoitemCgsTotalVovhd + @CoitemCgsTotalOut
      end

      insert into matltran (RowPointer, ref_type, ref_num, ref_line_suf, ref_release
      , trans_type, qty, trans_date, item, whse, loc, lot, user_code, reason_code
      , lbr_cost, matl_cost, fovhd_cost, vovhd_cost, out_cost, cost, import_doc_id
      , emp_num, date_seq)
      values(@MatltranRowPointer, @MatltranRefType, @MatltranRefNum, @MatltranRefLineSuf, @MatltranRefRelease
      , @MatltranTransType, @MatltranQty, @MatltranTransDate, @MatltranItem, @MatltranWhse, @MatltranLoc, @MatltranLot, @MatltranUserCode, @MatltranReasonCode
      , @MatltranLbrCost, @MatltranMatlCost, @MatltranFovhdCost, @MatltranVovhdCost, @MatltranOutCost, @MatltranCost, @ImportDocId
      , @EmpNum, @MatltranShipDateSeq)

      SELECT @MatltranTransNum = trans_num
      FROM matltran
      WHERE RowPointer = @MatltranRowPointer
      
      
      declare @_KPISerialShip integer
      declare @_KPILottracked integer
      select @_KPISerialShip = ISNULL(item.Uf_SerialShip, 0) ,
      @_KPILottracked = ISNULL(item.lot_tracked,0)
      from item 
      (nolock) where item.item = @MatltranItem
      
	   -- _KPI 03/22/17
	   -- _KPI 03/22/17 - 
	
	   if @_KPISerialShip = 1
	   begin
	        declare @_KPISerialCount integer
	        declare @_KPIMatlCount integer
	        
	         select @_KPIMatlCount =  @SQty
	                     
	         select @_KPISerialCount = count(1) from 
	        _KPI_BarCodes Barcode (nolock)
			 where 
				RefNum = @SCoNum and 
				RefLine = @SCoLine and
				BarCode.UserId = dbo.UserId() and
				MatlTransNum = 0
				
				
				
			select @_KPISerialCount = isnull(@_KPISerialCount,0)
			
			if @_KPIMatlCount <> @_KPIMatlCount
			begin
			 set @infobar = 'Serial Number Count Error'
			 return 16
			end 
		end
		
		if @_KPILottracked = 1 and @_KPISerialShip = 0
		begin
		 
			insert _KPI_BarCodes
			(BarCode,Lot,Item,SerialNum,qty,MatlTransNum, RefNum,Refline,Pack_Num, UserId)
			select @MatltranLot + CONVERT(nvarchar(10),@MatltranTransNum),@matltranLot,@CoitemItem,'N/A',@sqty,@MatltranTransNum,@SCoNum,@SCoLine,0, 0
		end
		
			update _KPI_BarCodes
			set MatlTransNum = @MatltranTransNum
   			from _KPI_BarCodes Barcode
			where 
				RefNum = @SCoNum and 
				RefLine = @SCoLine and
				barcode.UserId = dbo.UserId() and
				MatlTransNum = 0
	    if @_KPISerialShip = 1
	    begin
           insert dbo._KPI_Serials
			( 
			  site_ref, 
			  Item, 
			  SerialNum, 
			  Stat, 
			  Ref_type, 
			  RefNum, 
			  RefLine, 
			  RefLineSuf, 
			  Pack_Num, 
			  InvNum, 
			  TransDate,
			  CreatedBy, 
			  UpdatedBy, 
			  CreateDate, 
			  RecordDate, 
			  UserId
			  )
			  
			  
			  select 
			  
			  site_ref, 
			  Item, 
			  SerialNum, 
			  'O', 
			  Ref_type, 
			  RefNum, 
			  RefLine, 
			  RefLineSuf, 
			  Pack_Num, 
			  InvNum, 
			  TransDate,
			  CreatedBy, 
			  UpdatedBy, 
			  CreateDate, 
			  RecordDate, 
			  UserId
            
       
            from _KPI_BarCodes Barcode
			where 
				RefNum = @SCoNum and 
				RefLine = @SCoLine and
				barcode.UserId = dbo.UserId() and
				MatlTransNum = 0
            and barcode.SerialNum not in
            (
            select SerialNum from _KPI_Serials Ser (nolock)
            where Ser.Stat = 'O'
            )
            
            
        -- Update Exiting Serials with status (O)ut of Inventory    
            update _KPI_Serials
            set stat = 'O' from _KPI_Serials ser where ser.SerialNum in 
            (select SerialNum from _KPI_BarCodes Barcode
			where 
				RefNum = @SCoNum and 
				RefLine = @SCoLine and
				barcode.UserId = dbo.UserId() and
				MatlTransNum = 0
			 )
			 
	   end
	 -- _KPI End of Custom Serial Logic 
   

      if (@ProdcodeRowPointer is not null)
      BEGIN
         SET @TCgsAcctUnit2      = CASE WHEN @TCgsAcctUnit2 IS NOT NULL THEN @TCgsAcctUnit2 else dbo.ValUnit2(@TCgsAcct, @ProdcodeUnit, NULL) END
         SET @TCgsLbrAcctUnit2   = CASE WHEN @TCgsLbrAcctUnit2 IS NOT NULL THEN @TCgsLbrAcctUnit2 else dbo.ValUnit2(@TCgsLbrAcct, @ProdcodeUnit, NULL) END
         SET @TCgsFovhdAcctUnit2 = CASE WHEN @TCgsFovhdAcctUnit2 IS NOT NULL THEN @TCgsFovhdAcctUnit2 else dbo.ValUnit2(@TCgsFovhdAcct, @ProdcodeUnit, NULL) END
         SET @TCgsVovhdAcctUnit2 = CASE WHEN @TCgsVovhdAcctUnit2 IS NOT NULL THEN @TCgsVovhdAcctUnit2 else dbo.ValUnit2(@TCgsVovhdAcct, @ProdcodeUnit, NULL) END
         SET @TCgsOutAcctUnit2   = CASE WHEN @TCgsOutAcctUnit2 IS NOT NULL THEN @TCgsOutAcctUnit2 else dbo.ValUnit2(@TCgsOutAcct, @ProdcodeUnit, NULL) END
      END

      SET @TTotPostLbr   = round(@TTotPostLbr, @TDomPlaces)
      SET @TTotPostMatl  = round(@TTotPostMatl, @TDomPlaces)
      SET @TTotPostFovhd = round(@TTotPostFovhd, @TDomPlaces)
      SET @TTotPostVovhd = round(@TTotPostVovhd, @TDomPlaces)
      SET @TTotPostOut   = round(@TTotPostOut, @TDomPlaces)

      SET @TAdjPostLbr   = round(@TAdjPostLbr, @TDomPlaces)
      SET @TAdjPostMatl  = round(@TAdjPostMatl, @TDomPlaces)
      SET @TAdjPostFovhd = round(@TAdjPostFovhd, @TDomPlaces)
      SET @TAdjPostVovhd = round(@TAdjPostVovhd, @TDomPlaces)
      SET @TAdjPostOut   = round(@TAdjPostOut, @TDomPlaces)


      set @MatltranAmt1RowPointer = newid()
      SET @MatltranAmt1TransNum = @MatltranTransNum
      SET @MatltranAmt1TransSeq = 1
      SET @MatltranAmt1LbrAmt   = - (@TTotPostLbr   + @TAdjPostLbr)
      SET @MatltranAmt1MatlAmt  = - (@TTotPostMatl  + @TAdjPostMatl)
      SET @MatltranAmt1FovhdAmt = - (@TTotPostFovhd + @TAdjPostFovhd)
      SET @MatltranAmt1VovhdAmt = - (@TTotPostVovhd + @TAdjPostVovhd)
      SET @MatltranAmt1OutAmt   = - (@TTotPostOut   + @TAdjPostOut)

      SET @MatltranAmt1Amt = @MatltranAmt1LbrAmt + @MatltranAmt1MatlAmt + @MatltranAmt1FovhdAmt + @MatltranAmt1VovhdAmt + @MatltranAmt1OutAmt

      SET @MatltranAmt1Acct = NULL /* COGS */

      SET @MatltranAmt1LbrAcct   = @TCgsLbrAcct
      SET @MatltranAmt1LbrAcctUnit1   = @TCgsLbrAcctUnit1
      SET @MatltranAmt1LbrAcctUnit2   = @TCgsLbrAcctUnit2
      SET @MatltranAmt1LbrAcctUnit3   = @TCgsLbrAcctUnit3
      SET @MatltranAmt1LbrAcctUnit4   = @TCgsLbrAcctUnit4
      SET @MatltranAmt1MatlAcct  = @TCgsAcct
      SET @MatltranAmt1MatlAcctUnit1  = @TCgsAcctUnit1
      SET @MatltranAmt1MatlAcctUnit2  = @TCgsAcctUnit2
      SET @MatltranAmt1MatlAcctUnit3  = @TCgsAcctUnit3
      SET @MatltranAmt1MatlAcctUnit4  = @TCgsAcctUnit4
      SET @MatltranAmt1FovhdAcct = @TCgsFovhdAcct
      SET @MatltranAmt1FovhdAcctUnit1 = @TCgsFovhdAcctUnit1
      SET @MatltranAmt1FovhdAcctUnit2 = @TCgsFovhdAcctUnit2
      SET @MatltranAmt1FovhdAcctUnit3 = @TCgsFovhdAcctUnit3
      SET @MatltranAmt1FovhdAcctUnit4 = @TCgsFovhdAcctUnit4
      SET @MatltranAmt1VovhdAcct = @TCgsVovhdAcct
      SET @MatltranAmt1VovhdAcctUnit1 = @TCgsVovhdAcctUnit1
      SET @MatltranAmt1VovhdAcctUnit2 = @TCgsVovhdAcctUnit2
      SET @MatltranAmt1VovhdAcctUnit3 = @TCgsVovhdAcctUnit3
      SET @MatltranAmt1VovhdAcctUnit4 = @TCgsVovhdAcctUnit4
      SET @MatltranAmt1OutAcct   = @TCgsOutAcct
      SET @MatltranAmt1OutAcctUnit1   = @TCgsOutAcctUnit1
      SET @MatltranAmt1OutAcctUnit2   = @TCgsOutAcctUnit2
      SET @MatltranAmt1OutAcctUnit3   = @TCgsOutAcctUnit3
      SET @MatltranAmt1OutAcctUnit4   = @TCgsOutAcctUnit4

      insert into matltran_amt (RowPointer, trans_num, trans_seq
      , lbr_amt, matl_amt, fovhd_amt, vovhd_amt, out_amt, amt
      , acct, lbr_acct, lbr_acct_unit1, lbr_acct_unit2, lbr_acct_unit3, lbr_acct_unit4
      , matl_acct, matl_acct_unit1, matl_acct_unit2, matl_acct_unit3, matl_acct_unit4
      , fovhd_acct, fovhd_acct_unit1, fovhd_acct_unit2, fovhd_acct_unit3, fovhd_acct_unit4
      , vovhd_acct, vovhd_acct_unit1, vovhd_acct_unit2, vovhd_acct_unit3, vovhd_acct_unit4
      , out_acct, out_acct_unit1, out_acct_unit2, out_acct_unit3, out_acct_unit4)
      values(@MatltranAmt1RowPointer, @MatltranAmt1TransNum, @MatltranAmt1TransSeq
      , @MatltranAmt1LbrAmt, @MatltranAmt1MatlAmt, @MatltranAmt1FovhdAmt, @MatltranAmt1VovhdAmt, @MatltranAmt1OutAmt, @MatltranAmt1Amt
      , @MatltranAmt1Acct, @MatltranAmt1LbrAcct, @MatltranAmt1LbrAcctUnit1, @MatltranAmt1LbrAcctUnit2, @MatltranAmt1LbrAcctUnit3, @MatltranAmt1LbrAcctUnit4
      , @MatltranAmt1MatlAcct, @MatltranAmt1MatlAcctUnit1, @MatltranAmt1MatlAcctUnit2, @MatltranAmt1MatlAcctUnit3, @MatltranAmt1MatlAcctUnit4
      , @MatltranAmt1FovhdAcct, @MatltranAmt1FovhdAcctUnit1, @MatltranAmt1FovhdAcctUnit2, @MatltranAmt1FovhdAcctUnit3, @MatltranAmt1FovhdAcctUnit4
      , @MatltranAmt1VovhdAcct, @MatltranAmt1VovhdAcctUnit1, @MatltranAmt1VovhdAcctUnit2, @MatltranAmt1VovhdAcctUnit3, @MatltranAmt1VovhdAcctUnit4
      , @MatltranAmt1OutAcct, @MatltranAmt1OutAcctUnit1, @MatltranAmt1OutAcctUnit2, @MatltranAmt1OutAcctUnit3, @MatltranAmt1OutAcctUnit4)

      set @MatltranAmt2RowPointer = newid()
      SET @MatltranAmt2TransNum = @MatltranTransNum
      SET @MatltranAmt2TransSeq = 2
      SET @MatltranAmt2LbrAmt   = @TTotPostLbr
      SET @MatltranAmt2MatlAmt  = @TTotPostMatl
      SET @MatltranAmt2FovhdAmt = @TTotPostFovhd
      SET @MatltranAmt2VovhdAmt = @TTotPostVovhd
      SET @MatltranAmt2OutAmt   = @TTotPostOut

      SET @MatltranAmt2Amt = @MatltranAmt2LbrAmt + @MatltranAmt2MatlAmt + @MatltranAmt2FovhdAmt + @MatltranAmt2VovhdAmt + @MatltranAmt2OutAmt

      SET @MatltranAmt2Acct = NULL  /* INVENTORY ACCT */

      SET @MatltranAmt2MatlAcct = @ItemlocInvAcct
      SET @MatltranAmt2MatlAcctUnit1 = @ItemlocInvAcctUnit1
      SET @MatltranAmt2MatlAcctUnit2 = @ItemlocInvAcctUnit2
      SET @MatltranAmt2MatlAcctUnit3 = @ItemlocInvAcctUnit3
      SET @MatltranAmt2MatlAcctUnit4 = @ItemlocInvAcctUnit4
      SET @MatltranAmt2LbrAcct = @ItemlocLbrAcct
      SET @MatltranAmt2LbrAcctUnit1 = @ItemlocLbrAcctUnit1
      SET @MatltranAmt2LbrAcctUnit2 = @ItemlocLbrAcctUnit2
      SET @MatltranAmt2LbrAcctUnit3 = @ItemlocLbrAcctUnit3
      SET @MatltranAmt2LbrAcctUnit4 = @ItemlocLbrAcctUnit4
      SET @MatltranAmt2FovhdAcct = @ItemlocFovhdAcct
      SET @MatltranAmt2FovhdAcctUnit1 = @ItemlocFovhdAcctUnit1
      SET @MatltranAmt2FovhdAcctUnit2 = @ItemlocFovhdAcctUnit2
      SET @MatltranAmt2FovhdAcctUnit3 = @ItemlocFovhdAcctUnit3
      SET @MatltranAmt2FovhdAcctUnit4 = @ItemlocFovhdAcctUnit4
      SET @MatltranAmt2VovhdAcct = @ItemlocVovhdAcct
      SET @MatltranAmt2VovhdAcctUnit1 = @ItemlocVovhdAcctUnit1
      SET @MatltranAmt2VovhdAcctUnit2 = @ItemlocVovhdAcctUnit2
      SET @MatltranAmt2VovhdAcctUnit3 = @ItemlocVovhdAcctUnit3
      SET @MatltranAmt2VovhdAcctUnit4 = @ItemlocVovhdAcctUnit4
      SET @MatltranAmt2OutAcct = @ItemlocOutAcct
      SET @MatltranAmt2OutAcctUnit1 = @ItemlocOutAcctUnit1
      SET @MatltranAmt2OutAcctUnit2 = @ItemlocOutAcctUnit2
      SET @MatltranAmt2OutAcctUnit3 = @ItemlocOutAcctUnit3
      SET @MatltranAmt2OutAcctUnit4 = @ItemlocOutAcctUnit4

      insert into matltran_amt (RowPointer, trans_num, trans_seq
      , lbr_amt, matl_amt, fovhd_amt, vovhd_amt, out_amt, amt
      , acct, matl_acct, matl_acct_unit1, matl_acct_unit2, matl_acct_unit3, matl_acct_unit4
      , lbr_acct, lbr_acct_unit1, lbr_acct_unit2, lbr_acct_unit3, lbr_acct_unit4
      , fovhd_acct, fovhd_acct_unit1, fovhd_acct_unit2, fovhd_acct_unit3, fovhd_acct_unit4
      , vovhd_acct, vovhd_acct_unit1, vovhd_acct_unit2, vovhd_acct_unit3, vovhd_acct_unit4
      , out_acct, out_acct_unit1, out_acct_unit2, out_acct_unit3, out_acct_unit4, include_in_inventory_bal_calc)
      values(@MatltranAmt2RowPointer, @MatltranAmt2TransNum, @MatltranAmt2TransSeq
      , @MatltranAmt2LbrAmt, @MatltranAmt2MatlAmt, @MatltranAmt2FovhdAmt, @MatltranAmt2VovhdAmt, @MatltranAmt2OutAmt, @MatltranAmt2Amt
      , @MatltranAmt2Acct, @MatltranAmt2MatlAcct, @MatltranAmt2MatlAcctUnit1, @MatltranAmt2MatlAcctUnit2, @MatltranAmt2MatlAcctUnit3, @MatltranAmt2MatlAcctUnit4
      , @MatltranAmt2LbrAcct, @MatltranAmt2LbrAcctUnit1, @MatltranAmt2LbrAcctUnit2, @MatltranAmt2LbrAcctUnit3, @MatltranAmt2LbrAcctUnit4
      , @MatltranAmt2FovhdAcct, @MatltranAmt2FovhdAcctUnit1, @MatltranAmt2FovhdAcctUnit2, @MatltranAmt2FovhdAcctUnit3, @MatltranAmt2FovhdAcctUnit4
      , @MatltranAmt2VovhdAcct, @MatltranAmt2VovhdAcctUnit1, @MatltranAmt2VovhdAcctUnit2, @MatltranAmt2VovhdAcctUnit3, @MatltranAmt2VovhdAcctUnit4
      , @MatltranAmt2OutAcct, @MatltranAmt2OutAcctUnit1, @MatltranAmt2OutAcctUnit2, @MatltranAmt2OutAcctUnit3, @MatltranAmt2OutAcctUnit4, 1)

      set @MatltranAmt3RowPointer = newid()
      SET @MatltranAmt3TransNum = @MatltranTransNum
      SET @MatltranAmt3TransSeq = 3
      SET @MatltranAmt3Acct = @ProdcodeInvAdjAcct
      SET @MatltranAmt3AcctUnit1 = @ProdcodeInvAdjAcctUnit1
      SET @MatltranAmt3AcctUnit2 = CASE WHEN @ProdcodeInvAdjAcctUnit2 IS NOT NULL THEN @ProdcodeInvAdjAcctUnit2 ELSE dbo.ValUnit2(@ProdcodeInvAdjAcct, @ProdcodeUnit, NULL) END
      SET @MatltranAmt3AcctUnit3 = @ProdcodeInvAdjAcctUnit3
      SET @MatltranAmt3AcctUnit4 = @ProdcodeInvAdjAcctUnit4
      SET @MatltranAmt3Amt  = @TAdjPostLbr + @TAdjPostMatl + @TAdjPostFovhd + @TAdjPostVovhd + @TAdjPostOut

      insert into matltran_amt (RowPointer, trans_num, trans_seq
      , acct, acct_unit1, acct_unit2, acct_unit3, acct_unit4, amt)
      values(@MatltranAmt3RowPointer, @MatltranAmt3TransNum, @MatltranAmt3TransSeq
      , @MatltranAmt3Acct, @MatltranAmt3AcctUnit1, @MatltranAmt3AcctUnit2, @MatltranAmt3AcctUnit3, @MatltranAmt3AcctUnit4, @MatltranAmt3Amt)

      IF @ParmsPostJour <> 0
      BEGIN
         SET @TRef = CASE WHEN @SReturn <> 0 then 'INV CRT ' else 'INV CSH ' END

         if isnull(@MatltranAmt1MatlAmt, 0) != 0
         or isnull(@MatltranAmt1LbrAmt, 0) != 0
         or isnull(@MatltranAmt1FovhdAmt, 0) != 0
         or isnull(@MatltranAmt1VovhdAmt, 0) != 0
         or isnull(@MatltranAmt1OutAmt, 0) != 0
         or isnull(@MatltranAmt2MatlAmt, 0) != 0
         or isnull(@MatltranAmt2LbrAmt, 0) != 0
         or isnull(@MatltranAmt2FovhdAmt, 0) != 0
         or isnull(@MatltranAmt2VovhdAmt, 0) != 0
         or isnull(@MatltranAmt2OutAmt, 0) != 0
         or isnull(@MatltranAmt3Amt, 0) !=0
         begin
            set @ControlSite = @ParmsSite
            exec @Severity = dbo.NextControlNumberSp
              @JournalId = @TId
            , @TransDate = @MatltranTransDate
            , @ControlPrefix = @ControlPrefix output
            , @ControlSite = @ControlSite output
            , @ControlYear = @ControlYear output
            , @ControlPeriod = @ControlPeriod output
            , @ControlNumber = @ControlNumber output
            , @Infobar = @Infobar OUTPUT

            IF (@Severity >= 5)
               GOTO EOF
         end

         IF @CoShipmentApprovalRequired = 0
            SET @Tacct_label = '@distacct.cgs_lbr_acct'
         ELSE
            SET @Tacct_label = '@distacct.cgs_in_proc_lbr_acct'
         /* DR CGS Labor Account */
         EXEC @Severity = dbo.InvJourSp
            @JournalId = @TId
            , @acct       = @MatltranAmt1LbrAcct
            , @acct_unit1 = @MatltranAmt1LbrAcctUnit1
            , @acct_unit2 = @MatltranAmt1LbrAcctUnit2
            , @acct_unit3 = @MatltranAmt1LbrAcctUnit3
            , @acct_unit4 = @MatltranAmt1LbrAcctUnit4
            , @amount      = @MatltranAmt1LbrAmt
            , @caller      = @ProcName
            , @occur       = 'DRCGSLabor'
            , @ref_type    = @MatltranRefType
            , @ref_num     = @CoCoNum
            , @ref_line_suf = @CoitemCoLine
            , @ref_release = @CoitemCoRelease
            , @ref = @TRef
            , @trans_date  = @MatltranTransDate
            , @trans_num   = @MatltranTransNum
            , @vend_num    = @CoCustNum
            , @acct_label  = @Tacct_label
            , @file_label  = '@distacct'
            , @key_label_1 = '@prodcode.product_code'
            , @key_value_1 = @ProdcodeProductCode
            , @keys        = 1
            , @curr_code = @CurrparmsCurrCode
            , @ParmsPostJour = @ParmsPostJour
            , @ControlPrefix = @ControlPrefix
            , @ControlSite = @ControlSite
            , @ControlYear = @ControlYear
            , @ControlPeriod = @ControlPeriod
            , @ControlNumber = @ControlNumber
            , @Infobar = @Infobar OUTPUT
         IF (@Severity >= 5)
            GOTO EOF

         IF @CoShipmentApprovalRequired = 0
            SET @Tacct_label = '@distacct.cgs_acct'
         ELSE
            SET @Tacct_label = '@distacct.cgs_in_proc_matl_acct'
         /* DR CGS Material Account */
         EXEC @Severity = dbo.InvJourSp
            @JournalId = @TId
            , @acct       = @MatltranAmt1MatlAcct
            , @acct_unit1 = @MatltranAmt1MatlAcctUnit1
            , @acct_unit2 = @MatltranAmt1MatlAcctUnit2
            , @acct_unit3 = @MatltranAmt1MatlAcctUnit3
            , @acct_unit4 = @MatltranAmt1MatlAcctUnit4
            , @amount      = @MatltranAmt1MatlAmt
            , @caller      = @ProcName
            , @occur       = 'DRCGSMatl'
            , @ref_type    = @MatltranRefType
            , @ref_num     = @CoCoNum
            , @ref_line_suf = @CoitemCoLine
            , @ref_release = @CoitemCoRelease
            , @ref = @TRef
            , @trans_date  = @MatltranTransDate
            , @trans_num   = @MatltranTransNum
            , @vend_num    = @CoCustNum
            , @acct_label  = @Tacct_label
            , @file_label  = '@distacct'
            , @key_label_1 = '@prodcode.product_code'
            , @key_value_1 = @ProdcodeProductCode
            , @keys        = 1
            , @curr_code = @CurrparmsCurrCode
            , @ParmsPostJour = @ParmsPostJour
            , @ControlPrefix = @ControlPrefix
            , @ControlSite = @ControlSite
            , @ControlYear = @ControlYear
            , @ControlPeriod = @ControlPeriod
            , @ControlNumber = @ControlNumber
            , @Infobar = @Infobar OUTPUT
         IF (@Severity >= 5)
            GOTO EOF

         IF @CoShipmentApprovalRequired = 0
            SET @Tacct_label = '@distacct.cgs_fovhd_acct'
         ELSE
            SET @Tacct_label = '@distacct.cgs_in_proc_fovhd_acct'
         /* DR CGS Fix Overhead Account */
         EXEC @Severity = dbo.InvJourSp
            @JournalId = @TId
            , @acct       = @MatltranAmt1FovhdAcct
            , @acct_unit1 = @MatltranAmt1FovhdAcctUnit1
            , @acct_unit2 = @MatltranAmt1FovhdAcctUnit2
            , @acct_unit3 = @MatltranAmt1FovhdAcctUnit3
            , @acct_unit4 = @MatltranAmt1FovhdAcctUnit4
            , @amount      = @MatltranAmt1FovhdAmt
            , @caller      = @ProcName
            , @occur       = 'DRCGSFovhd'
            , @ref_type    = @MatltranRefType
            , @ref_num     = @CoCoNum
            , @ref_line_suf = @CoitemCoLine
            , @ref_release = @CoitemCoRelease
            , @ref = @TRef
            , @trans_date  = @MatltranTransDate
            , @trans_num   = @MatltranTransNum
            , @vend_num    = @CoCustNum
            , @acct_label  = @Tacct_label
            , @file_label  = '@distacct'
            , @key_label_1 = '@prodcode.product_code'
            , @key_value_1 = @ProdcodeProductCode
            , @keys        = 1
            , @curr_code = @CurrparmsCurrCode
            , @ParmsPostJour = @ParmsPostJour
            , @ControlPrefix = @ControlPrefix
            , @ControlSite = @ControlSite
            , @ControlYear = @ControlYear
            , @ControlPeriod = @ControlPeriod
            , @ControlNumber = @ControlNumber
            , @Infobar = @Infobar OUTPUT
         IF (@Severity >= 5)
            GOTO EOF

         IF @CoShipmentApprovalRequired = 0
            SET @Tacct_label = '@distacct.cgs_vovhd_acct'
         ELSE
            SET @Tacct_label = '@distacct.cgs_in_proc_vovhd_acct'
         /* DR CGS Var. Overhead Account */
         EXEC @Severity = dbo.InvJourSp
            @JournalId = @TId
            , @acct       = @MatltranAmt1VovhdAcct
            , @acct_unit1 = @MatltranAmt1VovhdAcctUnit1
            , @acct_unit2 = @MatltranAmt1VovhdAcctUnit2
            , @acct_unit3 = @MatltranAmt1VovhdAcctUnit3
            , @acct_unit4 = @MatltranAmt1VovhdAcctUnit4
            , @amount      = @MatltranAmt1VovhdAmt
            , @caller      = @ProcName
            , @occur       = 'DRCGSVovhd'
            , @ref_type    = @MatltranRefType
            , @ref_num     = @CoCoNum
            , @ref_line_suf = @CoitemCoLine
            , @ref_release = @CoitemCoRelease
            , @ref = @TRef
            , @trans_date  = @MatltranTransDate
            , @trans_num   = @MatltranTransNum
            , @vend_num    = @CoCustNum
            , @acct_label  = @Tacct_label
            , @file_label  = '@distacct'
            , @key_label_1 = '@prodcode.product_code'
            , @key_value_1 = @ProdcodeProductCode
            , @keys        = 1
            , @curr_code = @CurrparmsCurrCode
            , @ParmsPostJour = @ParmsPostJour
            , @ControlPrefix = @ControlPrefix
            , @ControlSite = @ControlSite
            , @ControlYear = @ControlYear
            , @ControlPeriod = @ControlPeriod
            , @ControlNumber = @ControlNumber
            , @Infobar = @Infobar OUTPUT
         IF (@Severity >= 5)
            GOTO EOF

         IF @CoShipmentApprovalRequired = 0
            SET @Tacct_label = '@distacct.cgs_out_acct'
         ELSE
            SET @Tacct_label = '@distacct.cgs_in_proc_out_acct'
         /* DR CGS Outside Account */
         EXEC @Severity = dbo.InvJourSp
            @JournalId = @TId
            , @acct       = @MatltranAmt1OutAcct
            , @acct_unit1 = @MatltranAmt1OutAcctUnit1
            , @acct_unit2 = @MatltranAmt1OutAcctUnit2
            , @acct_unit3 = @MatltranAmt1OutAcctUnit3
            , @acct_unit4 = @MatltranAmt1OutAcctUnit4
            , @amount      = @MatltranAmt1OutAmt
            , @caller      = @ProcName
            , @occur       = 'DRCGSOut'
            , @ref_type    = @MatltranRefType
            , @ref_num     = @CoCoNum
            , @ref_line_suf = @CoitemCoLine
            , @ref_release = @CoitemCoRelease
            , @ref = @TRef
            , @trans_date  = @MatltranTransDate
            , @trans_num   = @MatltranTransNum
            , @vend_num    = @CoCustNum
            , @acct_label  = @Tacct_label
            , @file_label  = '@distacct'
            , @key_label_1 = '@prodcode.product_code'
            , @key_value_1 = @ProdcodeProductCode
            , @keys        = 1
            , @curr_code = @CurrparmsCurrCode
            , @ParmsPostJour = @ParmsPostJour
            , @ControlPrefix = @ControlPrefix
            , @ControlSite = @ControlSite
            , @ControlYear = @ControlYear
            , @ControlPeriod = @ControlPeriod
            , @ControlNumber = @ControlNumber
            , @Infobar = @Infobar OUTPUT
         IF (@Severity >= 5)
            GOTO EOF

         IF @CoShipmentApprovalRequired = 0
            SET @Tacct_label = '@itemloc.lbr_acct'
         ELSE
            SET @Tacct_label = '@itemloc.lbr_in_proc_acct'
         /* CR Inv Labor Account */
         EXEC @Severity = dbo.InvJourSp
            @JournalId = @TId
            , @acct       = @MatltranAmt2LbrAcct
            , @acct_unit1 = @MatltranAmt2LbrAcctUnit1
            , @acct_unit2 = @MatltranAmt2LbrAcctUnit2
            , @acct_unit3 = @MatltranAmt2LbrAcctUnit3
            , @acct_unit4 = @MatltranAmt2LbrAcctUnit4
            , @amount      = @MatltranAmt2LbrAmt
            , @caller      = @ProcName
            , @occur       = 'CRInvLabor'
            , @ref_type    = @MatltranRefType
            , @ref_num     = @CoCoNum
            , @ref_line_suf = @CoitemCoLine
            , @ref_release = @CoitemCoRelease
            , @ref = @TRef
            , @trans_date  = @MatltranTransDate
            , @trans_num   = @MatltranTransNum
            , @vend_num    = @CoCustNum
            , @acct_label  = @Tacct_label
            , @file_label  = '@itemloc'
            , @key_label_1 = '@itemloc.whse'
            , @key_value_1 = @ItemlocWhse
            , @key_label_2 = '@itemloc.item'
            , @key_value_2 = @ItemlocItem
            , @key_label_3 = '@itemloc.loc'
            , @key_value_3 = @ItemlocLoc
            , @keys        = 3
            , @curr_code = @CurrparmsCurrCode
            , @ParmsPostJour = @ParmsPostJour
            , @ControlPrefix = @ControlPrefix
            , @ControlSite = @ControlSite
            , @ControlYear = @ControlYear
            , @ControlPeriod = @ControlPeriod
            , @ControlNumber = @ControlNumber
            , @Infobar = @Infobar OUTPUT
         IF (@Severity >= 5)
            GOTO EOF

         IF @CoShipmentApprovalRequired = 0
            SET @Tacct_label = '@itemloc.inv_acct'
         ELSE
            SET @Tacct_label = '@itemloc.inv_in_proc_acct'
         /* CR Inv Labor Account */
         /* CR Inv Material Account */
         EXEC @Severity = dbo.InvJourSp
            @JournalId = @TId
            , @acct       = @MatltranAmt2MatlAcct
            , @acct_unit1 = @MatltranAmt2MatlAcctUnit1
            , @acct_unit2 = @MatltranAmt2MatlAcctUnit2
            , @acct_unit3 = @MatltranAmt2MatlAcctUnit3
            , @acct_unit4 = @MatltranAmt2MatlAcctUnit4
            , @amount      = @MatltranAmt2MatlAmt
            , @caller      = @ProcName
            , @occur       = 'CRInvMatl'
            , @ref_type    = @MatltranRefType
            , @ref_num     = @CoCoNum
            , @ref_line_suf = @CoitemCoLine
            , @ref_release = @CoitemCoRelease
            , @ref = @TRef
            , @trans_date  = @MatltranTransDate
            , @trans_num   = @MatltranTransNum
            , @vend_num    = @CoCustNum
            , @acct_label  = @Tacct_label
            , @file_label  = '@itemloc'
            , @key_label_1 = '@itemloc.whse'
            , @key_value_1 = @ItemlocWhse
            , @key_label_2 = '@itemloc.item'
            , @key_value_2 = @ItemlocItem
            , @key_label_3 = '@itemloc.loc'
            , @key_value_3 = @ItemlocLoc
            , @keys        = 3
            , @curr_code = @CurrparmsCurrCode
            , @ParmsPostJour = @ParmsPostJour
            , @ControlPrefix = @ControlPrefix
            , @ControlSite = @ControlSite
            , @ControlYear = @ControlYear
            , @ControlPeriod = @ControlPeriod
            , @ControlNumber = @ControlNumber
            , @Infobar = @Infobar OUTPUT
         IF (@Severity >= 5)
            GOTO EOF

         IF @CoShipmentApprovalRequired = 0
            SET @Tacct_label = '@itemloc.fovhd_acct'
         ELSE
            SET @Tacct_label = '@itemloc.fovhd_in_proc_acct'
         /* CR Inv Fix Overhead Account */
         EXEC @Severity = dbo.InvJourSp
            @JournalId = @TId
            , @acct       = @MatltranAmt2FovhdAcct
            , @acct_unit1 = @MatltranAmt2FovhdAcctUnit1
            , @acct_unit2 = @MatltranAmt2FovhdAcctUnit2
            , @acct_unit3 = @MatltranAmt2FovhdAcctUnit3
            , @acct_unit4 = @MatltranAmt2FovhdAcctUnit4
            , @amount      = @MatltranAmt2FovhdAmt
            , @caller      = @ProcName
            , @occur       = 'CRInvFovhd'
            , @ref_type    = @MatltranRefType
            , @ref_num     = @CoCoNum
            , @ref_line_suf = @CoitemCoLine
            , @ref_release = @CoitemCoRelease
            , @ref = @TRef
            , @trans_date  = @MatltranTransDate
            , @trans_num   = @MatltranTransNum
            , @vend_num    = @CoCustNum
            , @acct_label  = @Tacct_label
            , @file_label  = '@itemloc'
            , @key_label_1 = '@itemloc.whse'
            , @key_value_1 = @ItemlocWhse
            , @key_label_2 = '@itemloc.item'
            , @key_value_2 = @ItemlocItem
            , @key_label_3 = '@itemloc.loc'
            , @key_value_3 = @ItemlocLoc
            , @keys        = 3
            , @curr_code = @CurrparmsCurrCode
            , @ParmsPostJour = @ParmsPostJour
            , @ControlPrefix = @ControlPrefix
            , @ControlSite = @ControlSite
            , @ControlYear = @ControlYear
            , @ControlPeriod = @ControlPeriod
            , @ControlNumber = @ControlNumber
            , @Infobar = @Infobar OUTPUT
         IF (@Severity >= 5)
            GOTO EOF

         IF @CoShipmentApprovalRequired = 0
            SET @Tacct_label = '@itemloc.vovhd_acct'
         ELSE
            SET @Tacct_label = '@itemloc.vovhd_in_proc_acct'
         /* CR Inv Var Overhead Account */
         EXEC @Severity = dbo.InvJourSp
            @JournalId = @TId
            , @acct       = @MatltranAmt2VovhdAcct
            , @acct_unit1 = @MatltranAmt2VovhdAcctUnit1
            , @acct_unit2 = @MatltranAmt2VovhdAcctUnit2
            , @acct_unit3 = @MatltranAmt2VovhdAcctUnit3
            , @acct_unit4 = @MatltranAmt2VovhdAcctUnit4
            , @amount      = @MatltranAmt2VovhdAmt
            , @caller      = @ProcName
            , @occur       = 'CRInvVovhd'
            , @ref_type    = @MatltranRefType
            , @ref_num     = @CoCoNum
            , @ref_line_suf = @CoitemCoLine
            , @ref_release = @CoitemCoRelease
            , @ref = @TRef
            , @trans_date  = @MatltranTransDate
            , @trans_num   = @MatltranTransNum
            , @vend_num    = @CoCustNum
            , @acct_label  = @Tacct_label
            , @file_label  = '@itemloc'
            , @key_label_1 = '@itemloc.whse'
            , @key_value_1 = @ItemlocWhse
            , @key_label_2 = '@itemloc.item'
            , @key_value_2 = @ItemlocItem
            , @key_label_3 = '@itemloc.loc'
            , @key_value_3 = @ItemlocLoc
            , @keys        = 3
            , @curr_code = @CurrparmsCurrCode
            , @ParmsPostJour = @ParmsPostJour
            , @ControlPrefix = @ControlPrefix
            , @ControlSite = @ControlSite
            , @ControlYear = @ControlYear
            , @ControlPeriod = @ControlPeriod
            , @ControlNumber = @ControlNumber
            , @Infobar = @Infobar OUTPUT
         IF (@Severity >= 5)
            GOTO EOF

         IF @CoShipmentApprovalRequired = 0
            SET @Tacct_label = '@itemloc.out_acct'
         ELSE
            SET @Tacct_label = '@itemloc.out_in_proc_acct'
         /* CR Inv Outside Account */
         EXEC @Severity = dbo.InvJourSp
            @JournalId = @TId
            , @acct       = @MatltranAmt2OutAcct
            , @acct_unit1 = @MatltranAmt2OutAcctUnit1
            , @acct_unit2 = @MatltranAmt2OutAcctUnit2
            , @acct_unit3 = @MatltranAmt2OutAcctUnit3
            , @acct_unit4 = @MatltranAmt2OutAcctUnit4
            , @amount      = @MatltranAmt2OutAmt
            , @caller      = @ProcName
            , @occur       = 'CRInvOut'
            , @ref_type    = @MatltranRefType
            , @ref_num     = @CoCoNum
            , @ref_line_suf = @CoitemCoLine
            , @ref_release = @CoitemCoRelease
            , @ref = @TRef
            , @trans_date  = @MatltranTransDate
            , @trans_num   = @MatltranTransNum
            , @vend_num    = @CoCustNum
            , @acct_label  = @Tacct_label
            , @file_label  = '@itemloc'
            , @key_label_1 = '@itemloc.whse'
            , @key_value_1 = @ItemlocWhse
            , @key_label_2 = '@itemloc.item'
            , @key_value_2 = @ItemlocItem
            , @key_label_3 = '@itemloc.loc'
            , @key_value_3 = @ItemlocLoc
            , @keys        = 3
            , @curr_code = @CurrparmsCurrCode
            , @ParmsPostJour = @ParmsPostJour
            , @ControlPrefix = @ControlPrefix
            , @ControlSite = @ControlSite
            , @ControlYear = @ControlYear
            , @ControlPeriod = @ControlPeriod
            , @ControlNumber = @ControlNumber
            , @Infobar = @Infobar OUTPUT
         IF (@Severity >= 5)
            GOTO EOF

         SET @Tacct_label = '@prodcode.inv_adj_acct'
         /* CR Inv Adjustment Account */
         EXEC @Severity = dbo.InvJourSp
            @JournalId = @TId
            , @acct       = @MatltranAmt3Acct
            , @acct_unit1 = @MatltranAmt3AcctUnit1
            , @acct_unit2 = @MatltranAmt3AcctUnit2
            , @acct_unit3 = @MatltranAmt3AcctUnit3
            , @acct_unit4 = @MatltranAmt3AcctUnit4
            , @amount      = @MatltranAmt3Amt
            , @caller      = @ProcName
            , @occur       = 'CRInvAdj'
            , @ref_type    = @MatltranRefType
            , @ref_num     = @CoCoNum
            , @ref_line_suf = @CoitemCoLine
            , @ref_release = @CoitemCoRelease
            , @ref = @TRef
            , @trans_date  = @MatltranTransDate
            , @trans_num   = @MatltranTransNum
            , @vend_num    = @CoCustNum
            , @acct_label  = @Tacct_label
            , @file_label  = '@prodcode'
            , @key_label_1 = '@prodcode.product_code'
            , @key_value_1 = @ProdcodeProductCode
            , @keys        = 1
            , @curr_code = @CurrparmsCurrCode
            , @ParmsPostJour = @ParmsPostJour
            , @ControlPrefix = @ControlPrefix
            , @ControlSite = @ControlSite
            , @ControlYear = @ControlYear
            , @ControlPeriod = @ControlPeriod
            , @ControlNumber = @ControlNumber
            , @Infobar = @Infobar OUTPUT
         IF (@Severity >= 5)
            GOTO EOF

      end
   END /* End Inventory Item Costing */
   /***************************** END COSTING ***************************/

   SET @ItemwhseQtySoldYtd = @ItemwhseQtySoldYtd - @TAdjQty

   UPDATE itemcust
      SET itemcust.ship_ytd = itemcust.ship_ytd - @TAdjQty
      where itemcust.cust_num = @CoCustNum
      and itemcust.item = @CoitemItem
      and isnull(itemcust.cust_item, nchar(1)) = isnull(@CoitemCustItem, nchar(1))

   IF @CoitemQtyShipped < @TAdjQty
   BEGIN
      BEGIN
         SET @MsgParm2 = dbo.UomConvQty(@CoitemQtyShipped, @UomConvFactor, 'From Base')

         EXEC @MsgSeverity = dbo.MsgAppSp @Infobar OUTPUT, 'E=NoCompare>'
            , '@coitem.qty_shipped', @MsgParm2
         IF @MsgSeverity >= ISNULL(@Severity, 0)
            SET @Severity = @MsgSeverity
      END

      GOTO EOF
   end

   SET @CoitemQtyShipped = @CoitemQtyShipped - @TAdjQty

   /* If a negative qty is shipped, the packed amount should be reduced so that
    * a new packing slip may be printed for the qty neg shipped */
   if @TAdjQty > 0 and @CoitemQtyPacked > 0
   BEGIN
      if @CoitemQtyPacked > 0 and @CoitemQtyPacked <> @CoitemQtyOrdered
      BEGIN
         EXEC @MsgSeverity = dbo.MsgAppSp @Infobar OUTPUT, 'COShippingTrxPostSpQtyToPackWarning'

         IF @MsgSeverity >= ISNULL(@Severity, 0)
            SET @Severity = @MsgSeverity
      END
      IF NOT( @ShipmentId is not null AND @SRetToStock = 0 AND @SReturn = 0)
      BEGIN
      SET @CoitemQtyPacked = dbo.MaxQty(0, @CoitemQtyPacked - @TAdjQty)
      END
     
  
   end
   
   if @TAdjQty > 0 and @CoitemQtyPicked > 0 and @ShipmentId is not null and (@SReturn = 1 or (@SReturn = 0 and @SRetToStock = 1))
   begin
      SET @CoitemQtyPicked = dbo.MaxQty(0, @CoitemQtyPicked - @TAdjQty)
   end

   if @SReturn = 0
   BEGIN
      if @CoitemQtyShipped > 0 and @NonInventoryItem <> 1
      BEGIN
         SET @TOrderBal = 0
         SET @CoitemLbrCost   = @AvgLbrCost
         SET @CoitemMatlCost  = @AvgMatlCost
         SET @CoitemFovhdCost = @AvgFovhdCost
         SET @CoitemVovhdCost = @AvgVovhdCost
         SET @CoitemOutCost   = @AvgOutCost
         SET @CoitemCost       = @CoitemLbrCost + @CoitemMatlCost + @CoitemFovhdCost + @CoitemVovhdCost + @CoitemOutCost
      END
   end
   else
   BEGIN
      SET @CoitemQtyReturned = @CoitemQtyReturned + @TAdjQty
      SET @TOrderBal = 0
   END

   if @TOrderBal <> 0.0
      EXEC dbo.CredChkSp
           @CustNum     = @CoCustNum
         , @Adjust      = @TOrderBal
         , @CoNum       = @CoCoNum
         , @OrigSite    = @CoOrigSite
         , @Infobar     = @Infobar OUTPUT

   IF @CoitemStat = 'F'
   and round(@CoitemQtyShipped - @CoitemQtyOrdered, @PlacesQtyUnit) < 0
   BEGIN
      SET @CoitemStat = 'O'
      /* If going from (F)illed to (O)rdered, the item master information
       * is updated to reflect the items that are ALLOC ORDER again.
       * We want to increase the On Order by the unshipped quantity. */
      SET @ItemwhseQtyAllocCo = @ItemwhseQtyAllocCo + @CoitemQtyOrdered - @CoitemQtyShipped
   END

   else if round(@CoitemQtyShipped - @CoitemQtyOrdered, @PlacesQtyUnit) >= 0 and @CoitemStat = 'O'
   BEGIN
      SET @CoitemStat = 'F'
      /* If going from (O)rdered to (F)illed, the item master information
       * is updated to reflect the items that are no longer ALLOC ORDER.
       * We want to reduce the Alloc Order by the quantity ordered minus the
       * total of all previous shipments, unless this is negative. */
      SET @ItemwhseQtyAllocCo = @ItemwhseQtyAllocCo -
         dbo.MaxQtySp(0.0, @CoitemQtyOrdered - (@CoitemQtyShipped + @TAdjQty))
   END
   else if @CoitemStat = 'O'
      SET @ItemwhseQtyAllocCo = @ItemwhseQtyAllocCo + @TAdjQty

   SET @ItemlocQtyOnHand = @ItemlocQtyOnHand + @TAdjQty

   update itemloc
   set
    qty_on_hand = @ItemlocQtyOnHand
   where RowPointer = @ItemlocRowPointer

   if @ItemLotTracked <> 0
   BEGIN
      SET @LotLocQtyOnHand = @LotLocQtyOnHand + @TAdjQty

      update lot_loc
      set
       qty_on_hand = @LotLocQtyOnHand
      where RowPointer = @LotLocRowPointer
   END

   /* IF NOT A RETURN AND SHIP QTY > 0 OR NEGATIVE CREDIT RETURN THEN DELETE SHIPPED RESERVED-QTYS */
   if @SReturn = 0 and @SQty > 0.0
   OR @SReturn = 1 and @SQty < 0.0
   BEGIN
      EXEC dbo.GetumcfSp
            @OtherUM    = @CoitemUM
          , @Item       = @CoitemItem
          , @VendNum    = @CoCustNum
          , @Area       = 'C'
          , @ConvFactor = @UomConvFactor OUTPUT
          , @Infobar    = @Infobar          OUTPUT
         , @Site = @ParmsSite

      IF (@Severity >= 5)
         GOTO EOF

      SET @TChosenResSerial = 0

      if @ItemSerialTracked <> 0
         UPDATE serial
         SET
            serial.stat = 'I'
            , serial.rsvd_num = NULL
            , serial.ref_type = 'O'
            , serial.ref_num = @CoShipCoNum
            , serial.ref_line = @CoShipCoLine
            , serial.ref_release = @CoShipCoRelease
            , serial.do_num = CASE when (@DoSeqRowPointer is not null) THEN @DoSeqDoNum ELSE serial.do_num END
            , serial.do_line = CASE when (@DoSeqRowPointer is not null) THEN @DoSeqDoLine ELSE serial.do_line END
            , serial.do_seq = CASE when (@DoSeqRowPointer is not null) THEN @DoSeqDoSeq ELSE serial.do_seq END
            /* Find out how many serial numbers were actually chosen from the
             * already reserved serial numbers in order to adjust the reserved qty
             * accurately */
            , @TChosenResSerial = @TChosenResSerial + 1
            , serial.import_doc_id = @ImportDocId
            , serial.shipment_id = @ShipmentId
         FROM serial
         INNER JOIN tmp_ser
         ON serial.ser_num = tmp_ser.ser_num
         where tmp_ser.SessionID = @SessionID
         and tmp_ser.ref_str = @SWorkkey
         and serial.stat = 'R'
         and serial.item = @CoitemItem

      select
       @RsvdInvRowPointer = rsvd_inv.RowPointer
      ,@RsvdInvQtyRsvd = rsvd_inv.qty_rsvd
      from rsvd_inv WITH (UPDLOCK)
      where rsvd_inv.ref_num = @CoitemCoNum
         and rsvd_inv.ref_line = @CoitemCoLine
         and rsvd_inv.ref_release = @CoitemCoRelease
         and rsvd_inv.loc = @SLoc
         and ISNULL(rsvd_inv.lot,'') = ISNULL(@SLot,'')

      if @@rowcount <> 1
         set @RsvdInvRowPointer = null

      if (@RsvdInvRowPointer is not null)
      BEGIN
         IF @ItemSerialTracked = 0
            SET @TChosenResSerial = dbo.MinQtySp(@RsvdInvQtyRsvd, @SQty)

         DECLARE @UpdResvAdjQty QtyUnitType

         IF @SReturn = 0 and @SQty > 0.0
            SET @UpdResvAdjQty = - @TChosenResSerial
         ELSE
            SET @UpdResvAdjQty = @TChosenResSerial

         EXEC dbo.UpdResvSp
              @DelRsvd       = 0
            , @RsiRowPointer = @RsvdInvRowPointer
            , @AdjQty        = @UpdResvAdjQty
            , @ConvFactor    = @UomConvFactor
            , @FromBase      = 'From Base'
            , @Infobar       = @Infobar OUTPUT
            , @SessionID     = @SessionID
         IF (@Severity >= 5)
            GOTO EOF
      end
   end

   select top 1
    @XCoShipRowPointer = x_co_ship.RowPointer
   ,@XCoShipShipDate = x_co_ship.ship_date
   from co_ship  as x_co_ship
   where x_co_ship.co_num = @CoitemCoNum
      AND x_co_ship.co_line = @CoitemCoLine
      AND x_co_ship.co_release = @CoitemCoRelease
   order by x_co_ship.ship_date desc
   if @@rowcount <> 1
      set @XCoShipRowPointer = null

   SET @CoitemShipDate = CASE WHEN (@XCoShipRowPointer is not null) then @XCoShipShipDate ELSE NULL END
   /* Check to see if it is a non-nettable location and a return.  If it is,
    * update the non-nettable on-hand qty instead of the qty on hand. */

   IF @ItemlocMrbFlag <> 0
      SET @ItemwhseQtyMrb = @ItemwhseQtyMrb + @TAdjQty
   else
      SET @ItemwhseQtyOnHand = @ItemwhseQtyOnHand + @TAdjQty

   SELECT
   @CoitemQtyRsvd = coitem.qty_rsvd
   FROM coitem WITH (UPDLOCK)
   WHERE coitem.co_num = @SCoNum
   and coitem.co_line = @SCoLine
   and coitem.co_release = @SCoRel
   and coitem.ship_site = @ParmsSite

   IF @NonInventoryItem <> 1
   BEGIN
      If @CoitemRefType = 'I' or (@CoitemRefType <> 'I' and @CoitemRefNum is not null)
      BEGIN
      SET @CoitemQtyReady = CASE WHEN @CoitemQtyRsvd > 0 then @CoitemQtyRsvd
         else dbo.MinQtySp(
            @CoitemQtyOrdered,
            dbo.MinQtySp(
               dbo.MaxQtySp(0.0,
                  @CoitemQtyReady +
                  CASE WHEN @CoitemQtyShipped <= @CoitemQtyOrdered
                     then dbo.MinQtySp(@TAdjQty, @CoitemQtyOrdered - @CoitemQtyShipped)
                     else dbo.MinQtySp(@TAdjQty, 0.0)
                  END
                  )
               ,
               dbo.MaxQtySp(0.0, @ItemwhseQtyOnHand - @ItemwhseQtyRsvdCo)
               )
            )
         END
      END
   END
   ELSE
      SET @CoitemQtyReady = dbo.MaxQty(0, dbo.MinQtySp(@SQty, @CoitemQtyOrdered - @CoitemQtyShipped))

   /* Replicate important updated coitem fields back to the orig-site, if can connect. */
   EXEC dbo.SynclineSp
        @CoNum      = @SCoNum
      , @CoLine     = @SCoLine
      , @CoRelease  = @SCoRel
      , @CoOrigSite = @CoOrigSite
      , @ShipSite   = @CoitemShipSite
      , @Infobar    = @Infobar OUTPUT

   IF CHARINDEX('Z', @ItemwhseCycleType) <> 0
   AND @ItemwhseQtyOnHand <= 0
      SET @ItemwhseCycleFlag = 1

   if @ItemlocQtyOnHand = 0 AND @ItemlocPermFlag = 0
   BEGIN
      /* Delete the itemloc if it's not the last itemloc with a
       * loc-type = 'S' for that whse and item. */
      EXEC @Severity = dbo.ItemlocDeleteSp
         @Whse   = @ItemlocWhse
         , @Item = @ItemlocItem
         , @Loc  = @ItemlocLoc
         , @Infobar = @Infobar output

      IF (@Severity >= 5)
         GOTO EOF
   end

   --  If a jobt_cls record is still pending, do not delete lot_loc record.
   if (@LotLocRowPointer is not null) AND @LotLocQtyOnHand = 0
   begin
      delete lot_loc where lot_loc.RowPointer = @LotLocRowPointer
      and not exists (select 1
       from jobt_cls with (readuncommitted)
       inner join matltran with (readuncommitted) on
         matltran.trans_num = jobt_cls.m_trans_num
       and matltran.item = lot_loc.item
       and matltran.whse = lot_loc.whse
       and matltran.loc = lot_loc.loc
       and matltran.lot = lot_loc.lot)
      set @LotLocRowPointer = null
   end

   if @ItemLotTracked <> 0 or @ItemSerialTracked <> 0 or @ItemTaxFreeMatl <> 0
   BEGIN
      DECLARE
         @MatltrackTrackType       TrackTypeType
         , @MatltrackTrackNum       MatlTransNumType
         , @TrackQty QtyUnitType

      SET @MatltrackTrackType = CASE WHEN @SReturn <> 0 THEN 'W' ELSE 'I' END
      SET @TrackQty = CASE WHEN @SReturn <> 0 THEN @SQty ELSE - @SQty END

      EXEC dbo.TrackSp
         @Item = @SItem
         , @TrackType = @MatltrackTrackType
         , @Loc = @SLoc
         , @Lot = @SLot
         , @Date = @STransDate
         , @DateSeq = @TDateSeq
         , @Qty  = @TrackQty
         , @RefType  = 'O'
         , @RefNum  = @SCoNum
         , @RefLineSuf = @SCoLine
         , @RefRelease = @SCoRel
         , @CustNum = @CustaddrCustNum
         , @VendNum = NULL
         , @TrackLink = 0
         , @Whse = @CoitemWhse
         , @WorkKey = @SWorkKey
         , @TrackNum = @MatltrackTrackNum OUTPUT
         , @ImportDocId = @ImportDocId
         , @SkipMatlTrack = 0

      declare tmp_ser_crs cursor local static for
      select
       tmp_ser.ser_num
      ,tmp_ser.RowPointer
      from tmp_ser WITH (UPDLOCK)
      where tmp_ser.SessionID = @SessionID
      and tmp_ser.ref_str = @SWorkkey

      open tmp_ser_crs
      while 1 = 1
      begin
         fetch tmp_ser_crs into
          @TmpSerSerNum
         ,@TmpSerRowPointer
         if @@fetch_status <> 0
            break

         select
          @SerialRowPointer = serial.RowPointer
         ,@SerialStat = serial.stat
         ,@SerialSerNum = serial.ser_num
         ,@SerialInvNum = serial.inv_num
         ,@SerialLoc = serial.loc
         ,@SerialLot = serial.lot
         ,@SerialWhse = serial.whse
         ,@SerialRefType = serial.ref_type
         ,@SerialRefNum = serial.ref_num
         ,@SerialRefLine = serial.ref_line
         ,@SerialRefRelease = serial.ref_release
         ,@SerialDoNum = serial.do_num
         ,@SerialDoLine = serial.do_line
         ,@SerialDoSeq = serial.do_seq
         ,@SerialItem = serial.item
         ,@SerialShipDate = serial.ship_date
         ,@SerialDateSeq = serial.date_seq
         ,@SerialCreateDate = serial.create_date
         ,@SerialPurgeDate = serial.purge_date
         ,@SerialExpDate = serial.exp_date
         ,@SerialShipmentId = serial.shipment_id
         from serial WITH (UPDLOCK)
         where serial.ser_num = @TmpSerSerNum
           AND serial.item = @SItem
         if @@rowcount <> 1
            set @SerialRowPointer = null

         if (@SerialRowPointer is not null)
         BEGIN
            /* Make sure that a serial number already shipped isn't chosen again */
            if (@SerialStat = 'O') and not ((@SReturn <> 0 and @SQty > 0) or (@SReturn = 0 and @SQty <= 0))
            BEGIN
               EXEC @Severity = dbo.MsgAppSp @Infobar OUTPUT, 'E=IsCompare3'
                  , '@serial.stat'
                  , '@:SerialStatus:O'
                  , '@item'
                  , '@serial.ser_num'
                  , @SerialSerNum
                  , '@co.co_num'
                  , @SCoNum
                  , '@coitem.co_line'
                  , @SCoLine

               GOTO EOF
            end

            if (@SerialStat = 'I') and ((@SReturn <> 0 and @SQty > 0) or (@SReturn = 0 and @SQty <= 0))
            BEGIN
               EXEC @Severity = dbo.MsgAppSp @Infobar OUTPUT, 'E=IsCompare3'
                  , '@serial.stat'
                  , '@:SerialStatus:I'
                  , '@item'
                  , '@serial.ser_num'
                  , @SerialSerNum
                  , '@co.co_num'
                  , @SCoNum
                  , '@coitem.co_line'
                  , @SCoLine

               GOTO EOF
            end

            SET @SerialStat = CASE WHEN ((@SReturn <> 0 and @SQty > 0) or (@SReturn = 0 and @SQty <= 0)) then 'I' else 'O' END
            SET @SerialInvNum = CASE WHEN ((@SReturn <> 0 and @SQty > 0) or (@SReturn = 0 and @SQty <= 0)) then '0' else @SerialInvNum END
            /* In case it's a return, this needs to be reset.  */
            SET @SerialLoc  = @SLoc
            /* In case it's a return, and they changed the lot this needs to be reset. */
            SET @SerialLot  = @SLot
            /* In case it's a return, and it's an old converted db this needs to be reset. */
            SET @SerialWhse  = @CoitemWhse

            if @SerialStat = 'O'
            BEGIN
               SET @SerialRefType = 'O'
               SET @SerialRefNum = @CoShipCoNum
               SET @SerialRefLine = @CoShipCoLine
               SET @SerialRefRelease = @CoShipCoRelease

               IF (@DoSeqRowPointer is not null)
               BEGIN
                  SET @SerialDoNum = @DoSeqDoNum
                  SET @SerialDoLine = @DoSeqDoLine
                  SET @SerialDoSeq = @DoSeqDoSeq
               END
            END
            ELSE
            BEGIN  -- Reset current
               SET @SerialShipDate   = NULL
               SET @SerialDateSeq    = 0
            END

            IF NOT ((@SReturn <> 0 and @SQty >= 0) or (@SReturn = 0 and @SQty <= 0))
               SET @SerialLoc = NULL

            update serial
            set
             stat = @SerialStat
            ,inv_num = @SerialInvNum
            ,loc = @SerialLoc
            ,lot = @SerialLot
            ,whse = @SerialWhse
            ,ref_type = @SerialRefType
            ,ref_num = @SerialRefNum
            ,ref_line = @SerialRefLine
            ,ref_release = @SerialRefRelease
            ,do_num = @SerialDoNum
            ,do_line = @SerialDoLine
            ,do_seq = @SerialDoSeq
            ,ship_date = @SerialShipDate
            ,date_seq = @SerialDateSeq
            ,import_doc_id = @ImportDocId
            ,shipment_id = @ShipmentId
            ,assigned_to_be_picked = 0
            where RowPointer = @SerialRowPointer
         end
         else
         BEGIN
            set @SerialRowPointer = newid()
            -- INITIALIZING VARS FOR TABLE INSERT
            SET @SerialInvNum     = ('0')
            SET @SerialDoNum      = NULL
            SET @SerialDoLine     = (0)
            SET @SerialDoSeq      = (0)

            SET @SerialSerNum = @TmpSerSerNum
            SET @SerialWhse = @CoitemWhse
            SET @SerialItem = @SItem
            SET @SerialLot = @SLot
            SET @SerialLoc = @SLoc
            SET @SerialRefType = 'O'
            SET @SerialRefNum = @CoShipCoNum
            SET @SerialRefLine = @CoShipCoLine
            SET @SerialRefRelease = @CoShipCoRelease
            SET @SerialShipmentId = @ShipmentId  -- @CoShipShipmentId ?

            IF (@DoSeqRowPointer is not null)
            BEGIN
               SET @SerialDoNum = @DoSeqDoNum
               SET @SerialDoLine = @DoSeqDoLine
               SET @SerialDoSeq = @DoSeqDoSeq
            END

            SET @SerialCreateDate = dbo.GetSiteDate(GETDATE())
            SET @SerialPurgeDate = @SerialCreateDate + @InvparmsRetentionDays
            SET @SerialExpDate = @SerialCreateDate + @ItemShelfLife
            SET @SerialStat = CASE WHEN (((@SReturn <> 0 and @SQty > 0) or (@SReturn = 0 and @SQty <= 0))) then 'I' else 'O' END

            IF NOT ((@SReturn <> 0 and @SQty >= 0) or (@SReturn = 0 and @SQty <= 0))
               SET @SerialLoc = NULL

            insert into serial (RowPointer, ser_num, whse, item, lot, loc
            , ref_type, ref_num, ref_line, ref_release
            , do_num, do_line, do_seq, create_date, purge_date, exp_date, stat, import_doc_id, shipment_id)
            values(@SerialRowPointer, @SerialSerNum, @SerialWhse, @SerialItem, @SerialLot, @SerialLoc
            , @SerialRefType, @SerialRefNum, @SerialRefLine, @SerialRefRelease
            , @SerialDoNum, @SerialDoLine, @SerialDoSeq, @SerialCreateDate, @SerialPurgeDate, @SerialExpDate, @SerialStat, @ImportDocId, @SerialShipmentId)
         end

         if @CallArg IS NULL OR @CallArg <> 'SAVE TMP-SER'
         begin
            delete tmp_ser where tmp_ser.RowPointer = @TmpSerRowPointer
            set @TmpSerRowPointer = null
         end

         -- Update shipment serials, if it is a return set shipped = 0
         if @ShipmentId is not null
         begin
            update shipment_seq_serial
            set shipped = CASE WHEN ((@SReturn <> 0 and @SQty > 0) or (@SReturn = 0 and @SQty <= 0)) then 0 else 1 END
            where shipment_seq_serial.shipment_id = @ShipmentId
              and shipment_seq_serial.ser_num = @TmpSerSerNum
         end
      end
      close tmp_ser_crs
      deallocate tmp_ser_crs
   end

   /*
    *  Check To See If CO Line Is XREFed To A Project  ***************
    */
   if @CoitemRefType = 'K'
      UPDATE proj
         SET proj.start_wip_rel = dbo.GetSiteDate(GETDATE())
         where proj.proj_num = @CoitemRefNum
         AND proj.wip_rel_method = 'S'
         AND proj.start_wip_rel IS NULL
END

--  Because the SumCoSp routine uses a total regeneration algorithmn, all
-- the coitem records are needed.  This lock is to prevent deadlock in cases
-- where multiple users are working with different coitem records on the same
-- order, like someone else is adding a release.

EXEC @Severity = dbo.LockCoSp
  @CoNum = @SCoNum
, @Lock  = 1

exec dbo.DefineVariableSp
  @VariableName  = 'SkipCoitemUpdateCustOrderBal'
, @VariableValue = '1'
, @Infobar       = @Infobar OUTPUT



IF @UM <> @CoitemUM
BEGIN
   EXEC dbo.GetumcfSp
         @OtherUM    = @CoitemUM
       , @Item       = @CoitemItem
       , @VendNum    = @CoCustNum
       , @Area       = 'C'
       , @ConvFactor = @UomConvFactor OUTPUT
       , @Infobar    = @Infobar          OUTPUT
      , @Site = @ParmsSite

   IF (@Severity >= 5)
      GOTO EOF
END
ELSE
   SET @UomConvFactor = 1

update coitem
set
 unit_weight = @CoitemUnitWeight
,cons_num = @CoitemConsNum
,cgs_total_lbr = @CoitemCgsTotalLbr
,cgs_total_matl = @CoitemCgsTotalMatl
,cgs_total_fovhd = @CoitemCgsTotalFovhd
,cgs_total_vovhd = @CoitemCgsTotalVovhd
,cgs_total_out = @CoitemCgsTotalOut
,cgs_total = @CoitemCgsTotal
,qty_shipped = @CoitemQtyShipped
,qty_returned = @CoitemQtyReturned
,qty_packed = @CoitemQtyPacked
,qty_picked = @CoitemQtyPicked
,qty_ready = @CoitemQtyReady
,ship_date = @CoitemShipDate
,stat = @CoitemStat
,lbr_cost = @CoitemLbrCost
,matl_cost = @CoitemMatlCost
,fovhd_cost = @CoitemFovhdCost
,vovhd_cost = @CoitemVovhdCost
,out_cost = @CoitemOutCost
,cost = @CoitemCost
,lbr_cost_conv = ISNULL(dbo.UomConvAmt(@CoitemLbrCost, @UomConvFactor, 'From Base'),0)
,matl_cost_conv = ISNULL(dbo.UomConvAmt(@CoitemMatlCost, @UomConvFactor, 'From Base'),0)
,fovhd_cost_conv = ISNULL(dbo.UomConvAmt(@CoitemFovhdCost, @UomConvFactor, 'From Base'),0)
,vovhd_cost_conv = ISNULL(dbo.UomConvAmt(@CoitemVovhdCost, @UomConvFactor, 'From Base'),0)
,out_cost_conv = ISNULL(dbo.UomConvAmt(@CoitemOutCost, @UomConvFactor, 'From Base'),0)
,cost_conv = ISNULL(dbo.UomConvAmt(@CoitemCost, @UomConvFactor, 'From Base'),0)
where RowPointer = @CoitemRowPointer

exec dbo.UndefineVariableSp
  @VariableName  = 'SkipCoitemUpdateCustOrderBal'
, @Infobar       = @Infobar OUTPUT

if round(@CoitemQtyShipped - @CoitemQtyOrdered, @PlacesQtyUnit) > 0
or round(@OrigCoitemQtyShipped - @CoitemQtyOrdered, @PlacesQtyUnit) > 0
begin
   declare @OBalQty QtyTotlType
   , @LinePrice AmtTotType

   set @OBalQty = dbo.MaxQty(@CoitemQtyShipped - @CoitemQtyOrdered, 0) - dbo.MaxQty(@OrigCoitemQtyShipped - @CoitemQtyOrdered, 0)

   set @LinePrice = 0
   EXEC @Severity = dbo.GetCoitemLinePriceSp
     @PCoNum            = @CoItemCoNum
   , @CoitemPrice       = @CoItemPrice
   , @CoitemDisc        = @CoItemDisc
   , @CoitemQtyOrdered  = @OBalQty
   , @CoitemLbrCost     = null
   , @CoitemMatlCost    = null
   , @CoitemFovhdCost   = null
   , @CoitemVovhdCost   = null
   , @CoitemOutCost     = null
   , @CoitemQtyInvoiced = 0
   , @CoitemQtyShipped  = 0
   , @CoitemPrgBillTot  = @CoItemPrgBillTot
   , @CoitemPrgBillApp  = @CoItemPrgBillApp
   , @CoitemCoLine      = @CoItemCoLine
   , @CoitemCoRelease   = @CoItemCoRelease
   , @CoitemItem        = @CoItemItem
   , @CoitemTaxCode1    = @CoItemTaxCode1
   , @CoitemTaxCode2    = @CoItemTaxCode2
   , @CoitemLinePrice   = @LinePrice OUTPUT
   , @Infobar           = @Infobar OUTPUT

   exec @Severity = dbo.CredChkSp
     @CustNum  = @CoCustNum
   , @Adjust   = @LinePrice
   , @CoNum    = @CoCoNum
   , @OrigSite = @CoOrigSite
   , @Infobar  = @Infobar OUTPUT
end

update itemwhse
set
 qty_alloc_co = @ItemwhseQtyAllocCo
,cycle_flag = @ItemwhseCycleFlag
,qty_sold_ytd = @ItemwhseQtySoldYtd
,qty_mrb = @ItemwhseQtyMrb
,qty_on_hand = @ItemwhseQtyOnHand
where RowPointer = @ItemwhseRowPointer

-- Update shipment data
IF @ShipmentId is not null
BEGIN
    SET @CoShipPrice = CASE WHEN @CoType = 'B'
          then @CoShipPrice
          else
             (CASE WHEN @CoParmsUseAltPriceCalc = 1 THEN
                 round((@CoShipPrice * (1 - @CoitemDisc / 100)), @CurrencyPlaces)
              ELSE
                 (@CoShipPrice * (1 - @CoitemDisc / 100))
              END)
       END

   SET @ShipmentValue = round(@CoShipQtyShipped * @CoShipPrice, @CurrencyPlaces)

   SET @ShipmentValue = @ShipmentValue - Round(@ShipmentValue * (@CoDisc / 100),@CurrencyPlaces)

   update shipment
   set value = value + @ShipmentValue 
      ,ship_date = @STransDate
   where shipment.shipment_id = @ShipmentId

   if @RsvdInvRowPointer is null
   begin
      update itemloc
      set assigned_to_be_picked_qty = assigned_to_be_picked_qty - @CoShipQtyShipped
      where itemloc.rowpointer = @ItemlocRowPointer
        and itemloc.assigned_to_be_picked_qty > 0

      if @LotLocRowPointer is not null
         update lot_loc
         set assigned_to_be_picked_qty = assigned_to_be_picked_qty - @CoShipQtyShipped
         where lot_loc.rowpointer = @LotLocRowPointer
           and lot_loc.assigned_to_be_picked_qty > 0
   end

   -- update pick_list_ref status
   update pick_list
   set status = 'S'
   from pick_list
      inner join pick_list_ref on
         pick_list_ref.pick_list_id = pick_list.pick_list_id
      inner join shipment_line on
         shipment_line.pick_list_id = pick_list_ref.pick_list_id
         and shipment_line.pick_list_ref_sequence = pick_list_ref.sequence
         and shipment_line.shipment_id = @ShipmentId
   where pick_list.status = 'A' 
END

IF @CoShipmentApprovalRequired <> 0 AND (@SReturn <> 0 and @SQty > 0)
BEGIN
/* Prepare co ship approval log */

   SET  @ControlPrefix = NULL
   SET  @ControlSite   = NULL
   SET  @ControlYear   = NULL
   SET  @ControlPeriod = NULL
   SET  @ControlNumber = NULL

   SET @ControlSite    = @ParmsSite
   EXEC @Severity      = dbo.NextControlNumberSp
        @JournalId     = @TId
      , @TransDate     = @MatltranTransDate
      , @ControlPrefix = @ControlPrefix OUTPUT
      , @ControlSite   = @ControlSite   OUTPUT
      , @ControlYear   = @ControlYear   OUTPUT
      , @ControlPeriod = @ControlPeriod OUTPUT
      , @ControlNumber = @ControlNumber OUTPUT
      , @Infobar       = @Infobar       OUTPUT

   IF (@Severity >= 5)
      GOTO EOF

-- Generate co ship approval log
   SET @TCoShipApprLogRowPointer    = newid()
   SET @TCoShipApprLogQtyAppr       = @SQty * -1
   SET @TCoShipApprLogApproveDate   = dbo.GetSiteDate ( GETDATE() )
   SET @TCoShipApprLogCONum         = @SCoNum
   SET @TCoShipApprLogCOLine        = @SCoLine
   SET @TCoShipApprLogCORelease     = @SCoRel
   SET @TCoShipApprLogShipDate      = @STransDate
   SET @TCoShipApprLogDateSeq       = @CoShipDateSeq
SELECT @TCoShipApprLogSeq           = 1 + ISNULL( (
                                SELECT MAX(sequence)
                                 FROM co_ship_approval_log WITH (READUNCOMMITTED)
                                 WHERE
                                      co_num     = @SCoNum
                                  AND co_line    = @SCoLine
                                  AND co_release = @SCoRel
                                  AND ship_date  = @STransDate
                                  AND date_seq   = @CoShipDateSeq
                                 ), 0)
    SET @TCoShipApprLogInvNum        = @SOrigInvoice
--    SET @TCoShipApprLogInvSeq        = 0
    SET @TCoShipApprLogControlPrefix = @ControlPrefix
    SET @TCoShipApprLogControlSite   = @ControlSite
    SET @TCoShipApprLogControlYear   = @ControlYear
    SET @TCoShipApprLogControlPeriod = @ControlPeriod
    SET @TCoShipApprLogControlNumber = @ControlNumber

   INSERT INTO co_ship_approval_log
   (
         RowPointer
       , qty_approved
       , approval_date
       , co_line
       , co_num
       , co_release
       , ship_date
       , date_seq
       , sequence
       , inv_num
--       , inv_seq
       , posted_control_prefix
       , posted_control_site
       , posted_control_year
       , posted_control_period
       , posted_control_number
   )
   VALUES
   (
         @TCoShipApprLogRowPointer
       , @TCoShipApprLogQtyAppr
       , @TCoShipApprLogApproveDate
       , @TCoShipApprLogCOLine
       , @TCoShipApprLogCONum
       , @TCoShipApprLogCORelease
       , @TCoShipApprLogShipDate
       , @TCoShipApprLogDateSeq
       , @TCoShipApprLogSeq
       , @TCoShipApprLogInvNum
--       , @TCoShipApprLogInvSeq
       , @TCoShipApprLogControlPrefix
       , @TCoShipApprLogControlSite
       , @TCoShipApprLogControlYear
       , @TCoShipApprLogControlPeriod
       , @TCoShipApprLogControlNumber
   )

END

--DO NOT DO AUTO RETURN
IF @SReturn = 0 AND @SQty >= 0
   BEGIN
      -- If Auto Update PO on demanding site
      IF @CoDemandingSitePoNum IS NOT NULL AND @CoDemandingSite IS NOT NULL
         EXEC @Severity = [dbo].[DemandingPoSourceCoSyncSp]
            @CoDemandingSite
           , @ParmsSite
           , @ParmsSite
           , @CoDemandingSite
           , @CoDemandingSitePoNum
           , @SCoNum
           , @SCoLine
           , @Infobar OUTPUT
           , @MatltranTransNum
   END

EOF:
IF (@Severity >= 5)
   -- Prepend Error conversation with primary key info:
   EXEC dbo.MsgPreSp @Infobar OUTPUT, 'E=CmdFailed3'
      , '@%post'
      , '@tmp_ship'
      , '@coitem.co_num'
      , @SCoNum
      , '@coitem.co_line'
      , @SCoLine
      , '@coitem.co_release'
      , @SCoRel
ELSE IF @Severity > 0
   -- Prepend Warning conversation with primary key info:
   EXEC dbo.MsgPreSp @Infobar OUTPUT, 'I=CmdSucceeded3'
      , '@%post'
      , '@tmp_ship'
      , '@coitem.co_num'
      , @SCoNum
      , '@coitem.co_line'
      , @SCoLine
      , '@coitem.co_release'
      , @SCoRel

RETURN @Severity




GO


