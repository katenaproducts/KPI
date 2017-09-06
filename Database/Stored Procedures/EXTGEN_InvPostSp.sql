USE [KPI_App]
GO

/****** Object:  StoredProcedure [dbo].[InvPostSp]    Script Date: 09/06/2017 11:22:51 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

/* $Header: /ApplicationDB/Stored Procedures/InvPostSp.sp 230   12/16/15 4:51p calagappan $ */
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
/* $Archive: /ApplicationDB/Stored Procedures/InvPostSp.sp $
 *
 * SL9.00.30 230 204761 calagappan Wed Dec 16 16:51:39 2015
 * Tax amount on final invoice becomes negative value from taxed on progressive bill.
 * Pass in undiscounted amount to TaxBaseSp
 *
 * SL9.00.30 229 204096 pgross Thu Nov 05 14:39:14 2015
 * Invoices not printing
 * corrected the assignment of distacct surcharge unit code variables
 *
 * SL9.00 228 194926 Cliu Thu May 21 22:58:32 2015
 * When a credit return is processed on an invoiced qualified order a record is created on the Earned Rebate Credit Workbench but cannot be processed.
 * Issue:194926
 * Add a restriction to type I invoice records when creating the earned rebate records.
 *
 * SL9.00 227 191515 Dmcwhorter Mon Mar 16 17:53:38 2015
 * Invoice amount is rounded on header level, though Consumption Tax Header Line Method is = 'Line'.
 * 191515 - Allow JP tax consumption to work with multiple lines.
 *
 * SL9.00 226 189937 Lchen3 Thu Jan 15 03:04:52 2015
 * One Invoice per Packing Slip is not workiing correctly
 * issue 189937
 * add packnum condition when One Invoice per Packing Slip checked on customer.
 *
 * $NoKeywords: $
 */
/* PREVIOUS COMMENTS
 *
 * SL9.00 225 188504 pgross Wed Dec 31 10:52:01 2014
 * Invoice amounts are not correct when there is a line discount and amount format with no decimals.
 * adjusted rounding of extended line amount
 *
 * SL9.00 224 188369 pgross Thu Dec 18 10:57:02 2014
 * Surcharges are created with amounts greater than 2 decimals in both the arinv and arinvd tables.   They are then posted through to A/R and payments cannot be posted against the invoice.
 * round the extended surcharge amount
 *
 * SL9.00 223 188748 pgross Tue Dec 16 15:10:24 2014
 * summarize surcharges for each individual invoice
 *
 * SL9.00 222 188432 Lchen3 Mon Dec 08 01:42:10 2014
 * Invoice Distributions are out of balance when Use Alternate Net Price Calculation is turned on
 * issue 188432
 * Add the condition of Use Alternate Net Price Calculation when calculate the Line Total Amount.
 *
 * SL9.00 221 185444 calagappan Tue Oct 07 10:32:48 2014
 * Incorrect journals generated in AR Dist when an invoice has been generated and posted from a customer order with an exchange rate and excise involved.
 * Store standard exchange rate as invoice exchange rate even under two exchange rates set up
 *
 * SL9.00 220 185014 Ltaylor2 Tue Sep 23 11:11:19 2014
 * Got error "Error Message does not exist. Object:PK__#7793A790__7887CBC9, Type:17" when run Order Invoicing/Credit Memo
 * Issue 185014 - Don't allow  insert of duplicate rows into @TmpCoShip and @TmpProgbill temp tables
 *
 * SL9.00 219 181497 pgross Mon Jul 07 11:13:19 2014
 * Order Invoice/Credit Memo - Tax Amount is set to zero when "Include Discount" field is cleared on Tax Codes form.
 * added surcharge variable initialization
 *
 * SL9.00 218 179331 pgross Thu Jul 03 14:35:15 2014
 * Invoice Amount is incorrect if generate from Packing Slip
 * adjusted co_ship.pack_num comparison
 *
 * SL9.00 217 181517 pgross Mon Jun 30 14:14:33 2014
 * the generated invoice amount is incorrect when ?Shipment Approval Required?ticked
 * update the co_ship_approval_log record even when updating arinvd records
 *
 * SL9.00 216 180140 Cliu Thu Jun 05 05:12:20 2014
 * Duplicate Serial Numbers in Serials table are being updated with invoice number when one of the records is invoiced
 * Issue:180140
 * It should consider the item when update invoice number in the seria table.
 *
 * SL9.00 215 176373 pgross Fri Mar 14 15:56:11 2014
 * Wrong calculation of Invoice amount when use two tax systems
 * pass total wholesale price to TaxPriceSeparationSp
 *
 * SL9.00 214 172469 Cliu Fri Dec 13 03:34:35 2013
 * The help for the Rebate Fair Value field on the Price Promotions and Rebates form is incorrect.
 * Issue:172469
 * Remove "/ 100" since the value 0.010 of rebate_redemption_rate and rebate_fair_value shall indicate a rate for 1%.
 *
 * SL9.00 213 172209 pgross Tue Nov 26 15:23:54 2013
 * Wrong Sales Tax when use Two Exchange Rates in Tax Parameters form.
 * corrected the Excise Exchange Rate calculation
 *
 * SL9.00 212 171424 Lchen3 Tue Nov 12 00:42:51 2013
 * After doing Cr Rtn for invoiced items shipped using Pick Pack Ship, no credit memo can be generated.
 * could create credit memo for a shipment which shipped from PPS
 *
 * SL8.04 211 163545 calagappan Tue Aug 06 15:31:59 2013
 * When negative unit price on progressively billed invoice ship invoice has wrong amounts
 * Changed how progressive bill amount to be applied and invoice amount are calculated when CO Line has negative unit price
 *
 * SL8.04 210 166376 Jmtao Tue Aug 06 03:52:18 2013
 * Cannot process mutiple CO Lines successfully at the same time in Invoice Builder form
 * 166376
 * 1. Add group by group by co.co_num for @CoList .
 * 2. change exists for the cursor co_Crs.
 *
 * SL8.04 209 166082 Tding Thu Aug 01 06:08:46 2013
 * Invoice generation not calculating Surcharge taxes
 * issue 166082 restore the change, and if Tax code is NULL on coitem, will check co.
 *
 * SL8.04 208 166082 Tding Wed Jul 31 04:30:25 2013
 * Invoice generation not calculating Surcharge taxes
 * issue 166082,  remove the coitem tax code judgement.
 *
 * SL8.04 207 165155 pgross Wed Jul 17 10:24:28 2013
 * Cannot invoice using packing slip number
 * improved handling of pre-ship packing slips
 *
 * SL8.04 206 159127 Dmcwhorter Wed Jul 03 14:50:39 2013
 * Price rounding is incorrect on Customer order lines as it multiplies by qty ordered before rounding
 * RS6172 - Alternate Net Price Calculation.
 *
 * SL8.04 205 163255 Tcecere Wed Jun 19 13:38:04 2013
 * Zero amount Earned Rebate entries and Credit Memos being created
 * Issue 163255 - Prevent creation of zero daollar earned_rebate records.
 *
 * SL8.04 204 163380 Mzhang4 Wed Jun 12 22:12:05 2013
 * Surcharge value null was added to invoice amount.
 * Issue163380
 *
 * SL8.04 203 163380 Mzhang4 Fri Jun 07 22:53:12 2013
 * Surcharge value null was added to invoice amount.
 * 163380-Set surcharge is 0 when it is null.
 *
 * SL8.04 202 RS5136 Mzhang4 Tue May 28 23:38:38 2013
 * RS5136- recalc sum surcharge on line level.
 *
 * SL8.04 201 RS5136 Mzhang4 Sun May 26 23:04:38 2013
 * RS5136- update surcharge add to sales tax.
 *
 * SL8.04 200 RS5136 Mzhang4 Tue May 21 05:35:05 2013
 * RS5136- Add section to create the inv_item_surcharge records and the corresponding arinvd record.
 *
 * SL8.04 199 162163 Lchen3 Thu May 16 05:08:41 2013
 * Original Invoice number and Reason do not print on Credit Memo
 * issue 162163
 * get the co_ship which returned quantity > 0
 *
 * SL8.04 198 159431 calagappan Mon Apr 22 18:24:41 2013
 * Freight is added to multiple invoices when one invoice per packing slip
 * When multiple invoices are created from packing slips, apply freight and misc charges on only one invoice
 *
 * SL8.04 197 RS5135 Mmarsolo Thu Mar 21 12:57:12 2013
 * RS5135: Add rate calculation and expire date calculation.
 * Combine the amount have same acct.
 * Correct the code, add acct judge from parameter.
 *
 * SL8.04 199 RS5135 Lliu Wed Mar 20 06:14:02 2013
 * RS5135: Correct the code, add acct judge from parameter.
 *
 * SL8.04 198 RS5135 Lliu Tue Mar 19 05:18:26 2013
 * RS5135: Combin the amount have same acct.
 *
 * SL8.04 196 RS5932 Bbai Fri Mar 15 03:29:44 2013
 * RS5932:
 * Make a change to include co_ship records that have a shipment_id and are credit card orders(co.payment_method = 'C')
 *
 * SL8.04 195 RS5135 Lliu Fri Mar 15 02:44:14 2013
 * RS5135: Add criteria choose the all promotion code that met, insert into arinvd at the same time.
 *
 * SL8.04 194 RS5135 Lliu Fri Mar 08 05:05:52 2013
 * RS5135: insert to Earned Rebates when Promotion Type is 'R'.
 *
 * SL8.04 193 RS2775 exia Wed Feb 20 04:11:29 2013
 * RS2775
 * Add to parameters.
 * If calledFrom is InvoiceBuilder, the source data will come from table tmp_invoice_builder.
 *
 * SL8.04 192 157970 calagappan Wed Feb 13 15:52:59 2013
 * When a credit return is processed on a Progressively billed line the amount is wrong.
 * Do not adjust credit return amount by progressive bill amount
 *
 * SL8.04 191 156737 calagappan Fri Dec 28 17:31:51 2012
 * Insert TrackRows to track documents created - to be used by report
 *
 * SL8.04 190 RS5421 Lliu Tue Nov 27 21:10:17 2012
 * RS5421: 
 *
 * SL8.04 189 RS5421 Lliu Fri Nov 23 04:25:27 2012
 * RS5421
 *
 * SL8.04 187 154801 calagappan Wed Nov 21 13:47:52 2012
 * With Apply to Progressive Billing parm unchecked in the Tax System & Include Disct chkd on Tax Code, final inv tax incorrect
 * Pass in extended amount not reduced by amount to apply to tax calculating procedure
 *
 * SL8.04 186 RS5421 Lliu Tue Nov 20 01:01:19 2012
 * RS5421: Update the qty_shipped to qty_approved when the Customer shipment approval is checked.
 *
 * SL8.04 185 154951 Cajones Mon Nov 19 14:30:09 2012
 * Issue 154951
 * -Added code to get/use new fields item.subject_to_excise_tax, item.excise_tax_percent to update inv_item.excise_tax_percent when appropriate.
 *
 * SL8.04 184 152592 pgross Tue Aug 28 16:59:24 2012
 * Extended price in Order Invoicing calculate a wrong.
 * the extended line amount is now determined by the displayed amounts instead of the base amounts
 *
 * SL8.04 183 135457 Bbai Thu Aug 16 03:55:53 2012
 * A message pops up when trying displaying a record has a large quantity over 10 digits to the left of the decimal with negative sign.
 * Issue 135457:
 * Change QtyPerType to QtyUnitType.
 *
 * SL8.04 182 151315 Cjin2 Tue Aug 07 02:34:31 2012
 * Distribution amount was posted to wrong account when it have Non-inventory-item.
 * 151315: Initialize @NonInventoryitem flag  before set it again.
 *
 * SL8.04 181 149185 pgross Wed Jun 27 13:36:57 2012
 * Final invoice wrong when CO had a negative progressive billing
 * do not overapply progressive bills
 *
 * SL8.03 180 148785 Cajones Wed May 16 11:33:37 2012
 * When order had multiple progressive bills on it, they are appearing in the wrong sequence on the printed invoice
 * Issue 148785
 * Modified the inv_pro SELECT: Removed inv_pro.inv_num from the ORDER BY, leaving only inv_pro.seq
 *
 * SL8.03 179 148119 Ltaylor2 Fri May 11 14:47:38 2012
 * 5325 - Pack and Ship design coding
 * Exclude co_ship records that have a shipment_id
 *
 * SL8.03 178 148361 calagappan Fri Apr 20 09:51:55 2012
 * when progressive billing box not checked invoice does not print
 * Initialize variable @CreateFromPackSlip
 *
 * SL8.03 177 148713 pgross Thu Apr 19 16:44:29 2012
 * Add logic to InvoicePostSp to validate custaddr.curr_code is not NULL
 * Issue 148713
 * do not skip orders with invalid currency codes
 *
 * SL8.03 176 148504 pgross Mon Apr 16 16:03:22 2012
 * After uncheck the Use Revision/Pay Days on the Customers form, the newly generated invoice from Customer Order would have a blank Approval Status
 * also check customer.use_revision_pay_days when determining arinv.approval_status
 *
 * SL8.03 175 146757 Mewing Wed Feb 01 10:57:45 2012
 * Error, Additional change needed for InvPostSp for DueDateSp change
 * 146757 - Error implementing RS 2953 call to DueDateSp failed
 *
 * SL8.03 174 145331 Mewing Mon Jan 23 15:11:37 2012
 * 145331 RS 2953 New Prox Discount Options
 *
 * SL8.03 173 144818 pgross Thu Jan 19 11:22:52 2012
 * Serial numbers do not print on the invoice
 * altered how Serial Numbers are selected
 *
 * SL8.03 172 145670 pgross Mon Dec 19 16:51:17 2011
 * When processing a price adjustment Invoice the wrong Sales Account number is debited.
 * corrected NULL account comparison for non-inventory items
 *
 * SL8.03 171 141061 calagappan Wed Nov 16 17:35:23 2011
 * OrderInvoicingCreditMemoDraft - Wrong draft amount stored in DB - Wrong draft amount stored in DB
 * Include freight and miscellaneous charges in payment distribution amount
 *
 * SL8.03 170 141183 Mmarsolo Tue Aug 09 16:42:56 2011
 * Invoice Hold cannot be unchecked in Customer Order Lines after the order has shipped
 * 141183 - Removed invoice_hold from cursor.
 *
 * SL8.03 168 141019 pgross Wed Aug 03 14:35:21 2011
 * no invoice created when use pre ship packing slip.
 * search for packing slips not tied to a co_ship record
 *
 * SL8.03 167 RS4978 EGriffiths Sat Jul 09 12:17:56 2011
 * RS4978 - Corrected DataTypes
 *
 * SL8.03 166 RS5156 chuang2 Fri Jun 03 06:49:51 2011
 * RS5156 Add parameter Invoice Hold. And if Invoice Hold is 1, then the line/release cannot be invoiced.  If the value is 0, it can.
 *
 * SL8.03 165 137057 pgross Fri May 06 13:23:31 2011
 * Invoice is only showing qty for 1st packing slip
 * corrected handling of multiple packing slips on a single invoice
 *
 * SL8.03 164 137514 pgross Wed Apr 06 13:56:55 2011
 * Multiple Due Date terms are not created
 * create ar_terms_due records for all Orders with multi-due date terms
 *
 * SL8.03 163 137118 pgross Fri Apr 01 14:17:17 2011
 * Invoice total is not rounding correctly
 * added rounding of co values
 *
 * SL8.03 162 137421 pgross Fri Apr 01 13:18:45 2011
 * removed creation of TrackRows records
 *
 * SL8.03 161 137075 pgross Thu Mar 17 09:24:07 2011
 * InvPostSp has Parameters in wrong order in call to EXTGEN
 * corrected the order of the EXTGEN parameters
 *
 * SL8.03 160 RS3639 Dhuang Wed Mar 02 01:35:28 2011
 * RS-3639-For noninv item changes
 *
 * SL8.03 159 135618 pgross Mon Jan 10 12:12:10 2011
 * Customer Order Line Invoice quantity incorrectly populated
 * properly increment values on coitem when a line is processed multiple times
 *
 * SL8.03 158 132624 calagappan Wed Sep 22 15:12:00 2010
 * Invoice not printing when using preprinted forms
 * Create invoices when preprinted forms is set to true
 *
 * SL8.03 157 132403 pgross Mon Sep 20 16:41:56 2010
 * Invoice amount generated 0.01 different when using tax for Mutil-Customer Order Lines
 * adjust tax amounts for small rounding differences
 *
 * SL8.03 156 132918 pgross Fri Sep 17 10:48:03 2010
 * Credits to Orders are not including the original tax amt if originally 100% Progressively Billed
 * set the taxable progressive billing amount to zero for Credit Memos
 *
 * SL8.03 155 132352 calagappan Fri Sep 03 13:31:08 2010
 * Commissions Due record is not updated for RMA generated and linked to CO from 'Apply to Invoice" field on the RMA Header
 * When credit memo is issued update commission due that was generated when original invoice was issued
 *
 * SL8.03 154 131723 calagappan Tue Aug 24 17:39:31 2010
 * Tax Basis is incorrect on Invoice
 * Consider freight, misc charges and accumulated amounts when calculating discount percent
 *
 * SL8.03 153 132440 pgross Thu Aug 19 15:13:39 2010
 * When you invoice more than 2,000 CO lines, you receive the error message "Invalid object name '#TmpInvHdr'.
 * do not drop temporary tables until processing is complete
 *
 * SL8.03 152 132276 pgross Tue Aug 10 16:47:45 2010
 * Credit generated from Credit return after Progressive Billing final invoice is incorrect
 * corrections to handle credit memos on progressive billed orders when returning entire line
 *
 * SL8.02 151 131031 calagappan Thu Jun 17 15:07:26 2010
 * Sales tax and sales tax basis are changing when order invoice is printed
 * Consider tax amounts when calculating discount percent
 *
 * SL8.02 150 130953 pgross Fri Jun 11 12:04:12 2010
 * Error Message Does Not Exist. Object: PK__#0A177EA__E04099540BFFC71B, Type 17
 * prevent including the same Serial number multiple times
 *
 * SL8.02 149 130187 Cajones Thu Jun 10 16:02:36 2010
 * Blank Invoice records are sent from Order Invoicing for Customers with EDI profile when print invoices is not checked.
 * Issue 130187
 * Added logic to not print an invoice if the customer has an EDI Customer Profile with the Print Invoice flag set to No.
 *
 * SL8.02 148 129578 Dmcwhorter Wed Apr 28 14:42:41 2010
 * Divide by Zero error encountered when printing a $0 invoice and the Order Discount Type is Amount
 * 129578 - Do not allow divide by zero when discount type is Amount.
 *
 * SL8.02 147 128864 pgross Wed Apr 14 11:33:52 2010
 * The credit memo generated from a CR RTN after invoicing a partial qty on a progressively billed CO is incorrect.
 * correction to previous revision
 *
 * SL8.02 146 128864 pgross Wed Apr 14 11:27:18 2010
 * The credit memo generated from a CR RTN after invoicing a partial qty on a progressively billed CO is incorrect.
 * corrected Progressive Billing calculation for Credit Memos
 *
 * SL8.02 145 rs4588 Dahn Thu Mar 04 14:36:49 2010
 * rs4588 copyright header changes
 *
 * SL8.02 144 126862 pgross Mon Feb 15 13:56:04 2010
 * Order Invoicing/Credit Memo - assigning wrong invoice number to serial numbers.
 * altered how serial records are chosen
 *
 * SL8.02 143 126762 pgross Fri Jan 15 13:35:46 2010
 * When generating distributions on the A/P Vouchers and Adjustments form, VAT is calculated to 4 decimal places instead of 2 decimal places causing the voucher total to be 4 decimal places.
 * round tmp_tax_calc.tax_amt
 *
 * SL8.02 142 121361 Mewing Mon Oct 12 14:51:30 2009
 * SL8.02 00 121361  All references to BatchId2Type need to be changed back to BatchIdType.  This checkin will affect stored procedures, triggers, functions.
 * Schema, property classes and component classes will be done seperately.
 *
 * SL8.01 141 123789 pgross Thu Sep 03 11:48:44 2009
 * Error message does not exist will appear When user trying to run OrderInvoicingCreditMemo with 'create from packslip' selected
 * update @TmpCoitem if it already exists instead of creating a new one
 *
 * SL8.01 140 121794 calagappan Thu Jul 23 14:18:00 2009
 * Invoice Posting fails on final invoice after progressive billing a negative Unit Price for CO line
 * Calculate progressive rounding amount even with negative unit prices.
 *
 * SL8.01 139 118687 calagappan Tue May 26 10:27:19 2009
 * Show a negative amount when CO-Line refer to two Progressive Billing Invoiced.
 * When evaluating progressive bill amounts exclude "Previously Invoiced" inv_pro rows.
 *
 * SL8.01 138 118985 Cajones Mon May 18 15:04:45 2009
 * Issue:118985,APAR:115322 - Changed references of type BatchIdType (defined as tinyint) to new UDDT BatchId2Type (defined as int).  This change is to allow the user to enter a 6 digit batch id number.
 *
 * SL8.01 137 116798 pgross Tue Jan 27 16:44:54 2009
 * Deadlock errors during invoicing with 'one invoice per packing slip' selected for POS
 * assign the pack_num to the correct variable
 *
 * SL8.01 136 116613 pgross Wed Jan 14 15:32:36 2009
 * Assigning a single date and compressing journal records for a large volume of data takes too long
 * build a list of co records to process without a lock and then loop on that list with a lock
 *
 * SL8.01 135 114590 calagappan Tue Oct 21 16:12:02 2008
 * Wrong amt at Invoice Report (when No disc in CO)
 * Revert fix for issue 109229
 *
 * SL8.01 134 113131 calagappan Mon Sep 08 12:11:42 2008
 * total amounts in invoice footer not correct on OrderInvoiceCreditMemo Report
 * Calculate discount percentage on-the-fly to improve precision.
 *
 * SL8.01 133 rs3953 Vlitmano Wed Aug 27 11:03:04 2008
 * RS3953 - Changed a Copyright header?
 *
 * SL8.01 131 RS4088 dgopi Fri Jun 06 08:27:25 2008
 * Making modifications as per RS4088
 *
 * SL8.01 130 RS4088 dgopi Fri Jun 06 08:21:38 2008
 * Making  modifications as per RS4088
 *
 * SL8.01 129 109229 Snenavat Sat May 31 05:57:52 2008
 * Total up extended price for every line item has different grand total amount in Order Invoicing. 
 * Issue - 109229
 * Removed round function for @ArinvdAmount
 *
 * SL8.01 128 RS4088 dgopi Wed May 21 01:58:04 2008
 * Making modifications as per RS4088
 *
 * SL8.01 127 108775 ljose Wed May 14 07:43:47 2008
 * Incorrect cash rounding on Sales Order and Invoice
 * 108775 Rounding of DistributionAmount also is done based on cashRoundingFactor.
 *
 * SL8.01 126 109027 ssalahud Fri May 09 06:10:38 2008
 * Arithmetic Overflow error when an invoice is being printed with large amount.
 * Issue 109027
 * 1. Modified the data type of columns 'amount' and 'tax_basis' in table '@arinvd' to Decimal(21,8).
 * 2. Modified the data type of columns 'sales_tax' and 'tax_basis' in table '@inv_stax' to Decimal(21,8).
 *
 * SL8.01 125 108846 psamudra Fri Apr 25 02:53:45 2008
 * Error in invoicing when using multiple due dates terms code
 * Issue#108846 Added parameter to AddARDuedateSeqSp which was missing prior.
 *
 * SL8.01 124 108825 rbathula Tue Apr 22 01:49:48 2008
 * Invoices are not printing with alpha-numeric and numeric sequences defined
 * Solving Issue: 108825
 * Condition to update @StartInvNum and @EndInvNum changed.
 *
 * SL8.00 123 106955 Dmcwhorter Mon Jan 14 15:03:58 2008
 * The EC VAT report is not utilising the dual exchange rate functionlity
 * 106955 - Correct setting of exchange rate when using excise rates.
 *
 * SL8.00 122 98490 ssalahud Wed Jan 02 09:50:33 2008
 * Invoice Distributions not= Posting Report not= Journal Entries - all three have different amounts
 * Issue 98490
 * Backed out changes made for the issue 96413.
 *
 * SL8.00 121 106973 Dmcwhorter Thu Dec 13 11:40:11 2007
 * The invoice total is incorrect when there are multiple Progressive Billings.
 * 106973 - Narrow when rounding done for issue 106318 is performed.
 *
 * SL8.00 120 106946 Dmcwhorter Wed Nov 21 14:11:09 2007
 * Invoice is showing zero dollar amount
 * 106946 - Fully shipped lines without progressive bills should not calculate a zero invoice total.
 *
 * SL8.00 119 106523 hcl-kumarup Fri Oct 26 00:52:45 2007
 * EC Sales List contains invalid records.
 * Issue 106523
 * Removed statement which reset to the ship to custaddr.country 
 *
 * SL8.00 117 106518 pgross Thu Oct 25 14:03:41 2007
 * When a Customer Order with an Order Level Discount has been completely Progressively Billed, subsequent Invoices for partial shipments are incorrect
 * altered how line net price is calculated
 *
 * SL8.00 116 101988 Dahn Wed Sep 05 15:20:43 2007
 * SQL Objects Wording - Some SPs and Numerous Scalar- Valued Functions
 * Changed header's comment (file dbo.AcctChgSp) to "Copyright ? 2007 Infor Global Solutions Technology GmbH, and/or its affiliate and subsidiaries.  All rights reserved.  The word and design marks set forth herein are trademarks and/or registered trademarks of Infor Global Solutions Technology GmbH and/or its affiliate and subsidiaries.  All rights reserved.  All other trademarks listed herein are the property of their respective owners."
 *
 * SL8.00 115 105057 pgross Thu Aug 30 11:52:31 2007
 * Apply To Invoice automatically getting populated with last invoice number for order on Credit Memo.
 * backed out my previous change and the change for Issue 95891
 *
 * SL8.00 114 105057 pgross Tue Aug 28 14:50:40 2007
 * Apply To Invoice automatically getting populated with last invoice number for order on Credit Memo.
 * get the apply_to_inv_num from the co_ship table instead of artran for credit memos
 *
 * SL8.00 113 104867 pcoate Wed Aug 22 14:48:33 2007
 * Progressive billed detail is incorrect on Invoice
 * Issue 104867 - Added logic to prevent unneeded "Less Previously Invoiced" detail lines from printing.
 *
 * SL8.00 112 103750 pcoate Tue Aug 21 10:21:53 2007
 * Unable to post the invoice
 * Issue 103750 - Backed out the changes made for issue 102387.
 *
 * SL8.00 111 98865 Kkrishna Mon Aug 20 01:38:38 2007
 * Invoice dates not being adjusted correctly for Revision Day processing
 * 98865 removed the statement SET DATEFIRST 1.
 *
 * SL8.00 110 98865 Kkrishna Fri Aug 10 07:00:11 2007
 * Invoice dates not being adjusted correctly for Revision Day processing
 * 98865 Altered formula for calculation of Invoice Date and Due Date
 *
 * SL8.00 109 96002 Dahn Fri Aug 03 11:43:49 2007
 * Draft customer not detected when ship to <> 0
 * Change validation for shipto and billto information.
 *
 * SL8.00 108 103707 pgross Fri Jul 27 15:13:48 2007
 * Entire Order header discount is applied to the product code of the first line of customer order when Sales and Sales Discount Accounts are the same.
 * match unit codes when finding @TmpArinvd for discounts
 *
 * SL8.00 107 103820 hcl-kumarup Thu Jul 26 06:13:57 2007
 * Apar 109027 Order Invoicing/Credit Memo printing all serial numbers shipped previous on last invoice.
 * Checked-in for issue# 103820
 * Modified WHERE clause in the query statement from "serial" table
 *
 * SL8.00 106 103084 hcl-kumarup Wed Jul 04 06:44:43 2007
 * After applying SL107230, invoice amount of CO with foreign currency is wrong.
 * Checked-in for issue 103084
 * Replaced @DomCurrencyPlaces by @CurrencyPlaces to get the correct currecny places of the different currency of different customer.
 *
 * SL8.00 105 102387 hcl-kumarup Fri Jun 29 08:46:01 2007
 * Invoices created after Progressive Billing with an Order Discount are not correct.
 * Checked-in for issue 102387
 * Removed the statement  SET @AmountToApply = @AmountToApply2
 * and applied SET @AmountToApply = (@XInvProAmount * @CoShipQtyShipped)/@CoitemQtyOrdered to get proportionate Progressive bill amount
 *
 * SL8.00 104 102667 magler Tue Jun 12 13:45:58 2007
 * Updated ETPs
 *
 * SL8.00 103 102133 hcl-dbehl Thu May 24 07:20:03 2007
 * Invoice printing fails when there are future Progressive Billing lines set to Automatic and the order line ships early
 * Issue# 102133
 * Changed the Unique Key of '@TmpProgBill' Table.
 *
 * SL8.00 102 100943 hcl-kumarup Fri Apr 20 06:58:35 2007
 * Serial number does not display on invoice
 * Checked-in for issue 100943
 * Allowed Updated to the Serial table by the current Invoice Number
 *
 * SL7.05 100 100943 hcl-kumarup Fri Apr 20 06:55:47 2007
 * Serial number does not display on invoice
 * Checked-in for issue 100943
 * Allowed Updated to the Serial table by the current Invoice Number
 *
 * SL7.05 99 101120 hcl-kumarup Thu Apr 19 02:27:11 2007
 * Credit is automatically being applied to the last invoice number associated to the order.
 * Checked-in for issue 101120
 * In case of credit memo generated from CR, the orig_inv_num of co_ship table is being refrred to get the apply to invoice number.
 *
 * SL7.05.10 99 101120 hcl-kumarup Thu Apr 19 02:23:41 2007
 * Credit is automatically being applied to the last invoice number associated to the order.
 * Checked-in for issue 101120
 * In case of credit memo generated from CR, the orig_inv_num of co_ship table is being refrred to get the apply to invoice number.
 *
 * SL7.05.10 98 100792 pgross Mon Apr 02 15:49:55 2007
 * Order Invoicing Credit Memo -  quantity invoiced in originating site is not updated.
 * do not skip the coitem trigger when cross-site is involved
 *
 * SL7.05.10 97 100348 hcl-kumarup Fri Mar 23 05:17:57 2007
 * Incorrect Credit Note amount when the pending qty-shipped > qty-return
 * Checked-in for issue 100348
 * Changes made to get correct credit note amount. Handled the Billed Amount in case of Qty Retruned and invoice type is Credit Memo.
 *
 * SL7.05 97 100348 hcl-kumarup Fri Mar 23 04:10:32 2007
 * Incorrect Credit Note amount when the pending qty-shipped > qty-return
 * Checked-in for issue 100348
 * Changes made to get correct credit note amount. Handled the Billed Amount in case of Qty Retruned and invoice type is Credit Memo.
 *
 * SL7.05 96 100377 hcl-kumarup Fri Mar 16 07:36:01 2007
 * Error message when invoicing if more than one invoice category and no start dates for categories
 * Cheked-in for issue 100377
 * Changes made to get correct invoice number if the invoice category is changed
 *
 * SL7.05 95 98614 hcl-tiwasun Thu Jan 11 05:05:17 2007
 * G/L Reference is not uniform when the invoice is manually added or posted from Order on "Invoices,Debit and Credit Memo"
 * Issue# 98614
 * Modified the sp to display space character in @ArinvRef variable.
 *
 * SL7.05 94 98380 hcl-tiwasun Thu Dec 28 08:26:07 2006
 * Error "3 form(s) were printed" while running "Order Invoicing and Credit Memo"
 * Issue# 98380
 * Modified the SP to overcome Divide By Zero error.
 *
 * SL7.05 93 97369 Hcl-chantar Wed Oct 25 05:07:27 2006
 * Credit Memo will not print if there were multiple returns against the same line, and some were not returned to stock
 * Issue 97369:
 * Added IF condition to calculate Credit Memo cost. It was giving error if quantity shipped was 0.
 *
 * SL7.05 92 96413 hcl-kumarup Thu Sep 28 06:39:15 2006
 * Include tax in price rounding problems.
 * Checked-in for issue 96413
 * Passed 50 to TaxCalcSp for Currecy Places param when currencypalces is 0. This is implemented according to CurrCnvtSp where 50 is used for "No Rounding at all"
 *
 * SL7.05 91 96184 hcl-kumarup Mon Sep 25 07:58:23 2006
 * After performed a partial Progressive Billing, fully shipment, the final invoice is not correct.
 * Checked-in for issue 96184
 * In case of Include tax in price option, deducted the total and net invoice amount by the progressive bill amount to calculate the tax on uninvoiced amount.
 *
 * SL7.05 90 95891 hcl-tiwasun Thu Sep 07 02:08:35 2006
 * Credit memo does not reference original invoice; posted as 'open'
 * Issue# 95891
 * Conditionally insert the value of ApplyToInvNum field in @TmpArinv Temporary table for credit memo.
 *
 * SL7.05 89 95716 pgross Thu Aug 10 16:55:27 2006
 * When creating a Credit Memo for a customer order that has been Progressively Billed the total amount on the Credit Memo is incorrect
 * corrected calculation of how much is to be applied to credit memos when progressive billing records exist for the CO
 *
 * SL7.05 88 90226 pgross Thu Jul 20 11:37:38 2006
 * InvPostSp blocks the co table for lengthy periods preventing work by many other users in related areas
 * 1)  replaced #tt_CounterTable usage with an output parameter
 * 2)  added transaction block
 *
 * SL7.05 87 94389 pgross Wed May 17 09:32:43 2006
 * Rounding Problem with Invoice Distribution and Invoices will not post
 * backed out the fix for Issue 92273 and applied a better fix for the problem
 *
 * SL7.05 86 93825 Hcl-chantar Thu May 04 03:09:28 2006
 * AR amount is wrong after applied single fix SL101997
 * Issue 93825:
 * Found again problem while posting invoice. Rounding was required at the time of inserting distribution records also.
 *
 * SL7.05 85 93825 Hcl-chantar Tue May 02 05:38:08 2006
 * AR amount is wrong after applied single fix SL101997
 * Issue 93825:
 * Found the similar problem for distribution amount. Added Round method.
 *
 * SL7.05 84 93825 Hcl-chantar Thu Apr 27 06:48:54 2006
 * AR amount is wrong after applied single fix SL101997
 * Issue 93825:
 * Added logic to round Sales Tax, Freight, Misc. Charges and Amount as per currency places defined for the domestic currency.
 *
 * SL7.05 83 93990 ajith.nair Thu Apr 27 04:19:37 2006
 * INIT db - 0 forms were printed
 * 93990
 * Reverted the changes done in the version 82
 *
 * SL7.05 82 93990 ajith.nair Wed Apr 26 02:17:58 2006
 * INIT db - 0 forms were printed
 * 93990
 * Modified the 'IF' condition after the 'Select' statement [Selection fields from the 'arparms' table] and added one more condition to check whether the ArparmsArAcct is Null
 * This will display valid error message when we process 'Order Invoice Credit Memo' report with blank account receivable parameter.
 *
 * SL7.05 81 93662 hcl-ajain Fri Apr 14 07:33:51 2006
 * Salesperson - the Sales PTD field does not update when a customer order is shipped, invoiced and the payment is collected from the Customer
 * Issue # 93662
 * Changed
 *              "                     UPDATE @TmpSlsman
 *                      SET sales_ytd = @SlsmanSalesYtd
 *                        , sales_ptd = @SlsmanSalesPtd
 *                   WHERE RowPointer = @SlsmanRowPointer"
 * to
 *                  UPDATE @TmpSlsman
 *                      SET sales_ytd =sales_ytd + @SlsmanSalesYtd
 *                        , sales_ptd =sales_ptd + @SlsmanSalesPtd
 *                   WHERE RowPointer = @SlsmanRowPointer
 *
 * SL7.05 80 91750 Hcl-mehtviv Thu Mar 23 01:05:26 2006
 * Packing Slip -  changing ship via on packing list does not change the ship via when print invoice.
 * Issue  91750:
 * Modifications have been made to print Ship-Via, if the invoice is created from packing slip.
 * @CoShipCode has been picked from pck_hdr for the same.
 *
 * SL7.05 79 93250 pgross Tue Mar 14 17:06:24 2006
 * Invoice Number is not being populated in Packing Slip item table
 * improved matching on pckitem
 *
 * SL7.05 78 92273 hcl-kumarup Thu Feb 16 04:56:42 2006
 * Invoice, Debit and credit Memos G/L Distribution form have a difference (0.01) at Tax Basis amount.
 * Checked in for Issue #92273
 * set Currency place value for rounding problem
 *
 * SL7.05 77 92020 Hcl-krisgee Thu Jan 19 00:15:20 2006
 * Order Invoicing only printing one line of one invoice each time invoice is performed
 * Checked-in for issue No:92020
 * Undone the changes done for issue 90503.
 *
 * SL7.04 76 91818 NThurn Fri Jan 06 11:41:17 2006
 * Inserted standard External Touch Point call.  (RS3177)
 *
 * SL7.04 75 91528 pcoate Tue Jan 03 11:38:51 2006
 * No tax info coming out on invoice from EDI customer orders
 * Issue 91528 - Moved logic that inserts records into inv_stax to occur before the call to EdiObDriverInvCSp, so that edi_inv_stax gets populated.
 *
 * SL7.04 74 90184 hcl-amargt Tue Jan 03 08:25:24 2006
 * Changes to SPs to improve performance
 * Issue : 90184
 * 1. Replaced the cursor loop for tax_calc_Crs to be an "INSERT INTO @TmpInvStax / SELECT FROM tmp_tax_calc" statement.
 * 2. Replaced the cursor loop for inv_stax_Crs to be an "INSERT INTO @TmpArinvd / SELECT FROM @TmpInvStax" statement.
 * 3. Moved the statement "SELECT @XCountry ... FROM country where country.country = @ParmsCountry" up to the top of the program.
 * 4. Moved the conditional statement "IF @TmpTermsUseMultiDueDates = 1 AND @TmpArinvType = 'I'" into the cursor definition for MultipleDueDateCrs.
 * 5. Changed the statement "INSERT INTO @TmpCoitem ... SELECT <fields> FROM coitem" to "INSERT INTO @TmpCoitem ... VALUES (<fields>)".
 * 6. Changed the statement "INSERT INTO @TmpArinvd ... SELECT <fields> FROM arinvd" to "INSERT INTO @TmpArinvd ... VALUES (<fields>)".
 * 7. Changed the statement "INSERT INTO @TmpCo ... SELECT <fields> FROM co" to "INSERT INTO @TmpCo ... VALUES (<fields>)".
 * 8. Changed the statement "INSERT INTO @TmpSlsman ... SELECT <fields> FROM slsman" to "INSERT INTO @TmpSlsman ... VALUES (<fields>)".
 * 9. All stored procedure calls were prefixed with "dbo.".
 *
 * SL7.04 73 91314 pcoate Fri Dec 16 13:18:27 2005
 * Issue 91314 - Added one line of code to zero out the co_sls_com commission percent value prior to processing the sales manager commission amount.
 *
 * SL7.04 72 90800 Hcl-krisgee Tue Dec 13 04:48:45 2005
 * Invoice Number is not updated on pckitem
 * Checked-in for issue No:90800
 * Undone the changes done for 87838 and modified the fix done for issue 90503.
 *
 * SL7.04 71 89721 Hcl-dixichi Mon Nov 28 01:09:48 2005
 * Order header amounts and invoices amounts are wrong when using order header discount type amount
 * Checked-in for issue 89721
 * Made changes for calculating correct sales tax and discount amount.
 *
 * SL7.04 70 90503 Hcl-krisgee Fri Nov 25 04:14:19 2005
 * The packing slip does not print on the invoice if there is a Ship to on the CO
 * Checked-in for issue No:90503
 * Modified the procedure InvPostsp to print packing slip on the invoice if there is a Ship to on the CO and the "Print Packing Slip on Invoice" field is checked on the customers form.
 *
 * SL7.04 69 90301 Hcl-chantar Fri Nov 11 04:15:01 2005
 * Sales Discount account is being picked up from Accounts Receivable Parameters instead of the Product Code Distribution Account
 * Issue 90301:
 * Corrected the order of fetching Discount account.
 *
 * SL7.04 68 88560 hcl-kumarup Tue Nov 08 04:45:44 2005
 * Order Discount type of amount used but % still being applied to invoice print
 * Checked in for Issue #88560
 * Coded for calulating discount amount for the invoice if the discount type is AmountType in the Customer Order in InvPostSp
 *
 * SL7.04 67 89839 Hcl-jainami Fri Oct 07 15:26:43 2005
 * Commdue table has wrong cust_num when more than one invoice printed at a time
 * Checked-in for issue 89839:
 * Picked the Customer Number from '@InvHdrCustNum' instead of '@CoCustNum'.
 *
 * SL7.04 66 89425 Hcl-krisgee Fri Sep 30 07:46:48 2005
 * Weight and Number of Packages are not printing on the invoice
 * Checked-in for issue No: 89425.
 * Modifications have been made to print weight and Qty packages, if the invoice is created from packing slip.
 *
 * SL7.04 65 89254 Hcl-dixichi Fri Sep 16 08:53:44 2005
 * Packing Slip # not printing on invoice
 * Checked-in for issue 89254
 * Handled the Packing Slip Number values correctly.
 *
 * SL7.04 64 89054 Hcl-guptman Tue Sep 06 03:40:01 2005
 * Amount displayed as zero in case of terms code with multiple due dates
 * Issue #89054
 * Modified SP to insert correct value of amount in ar_terms_due table when customer uses terms code with multiple due dates.
 *
 * SL7.04 63 88752 hcl-singind Fri Aug 26 07:55:06 2005
 * RS1228 Upgrade Localization for France
 * Issue # 88752.
 * Remove the following call to French stub from the SL7.04 base SP
 * ?IF OBJECT_ID('EXTFRInvPostSp') IS NOT NULL?
 *
 * SL7.04 62 88756 hcl-kumarup Wed Aug 24 09:28:14 2005
 * The invoice header cost is not correct when processing a range of customer orders
 * Checked in for  issue #88756
 * SET @InvHdrCost       = 0
 *
 * SL7.04 61 88571 Hcl-chantar Tue Aug 09 00:04:25 2005
 * Invoice will not print if more than one shipment on the same line and same packing slip
 * Issue 88571:
 * Changed
 * WHERE pckitem.pack_num IS NOT NULL
 * TO
 * WHERE pckitem.pack_num = @PackNum
 *
 * SL7.04 60 87838 Hcl-chantar Tue Jun 28 05:08:37 2005
 * The Invoice will not print if there are some Customer Ship-to records with Language code and other do not.
 * Issue 87838:
 * Modified the AND condition in the WHERE clause.
 *
 * SL7.04 59 87624 Grosphi Wed Jun 08 16:12:38 2005
 * Invoice Distribution - Dist Seq value wrong when CO has misc charges
 * corrected the assignment of arinvd.dist_seq for misc charges
 *
 * SL7.04 58 87425 Grosphi Fri Jun 03 10:36:21 2005
 * force DATEPART(WEEKDAY) to return 1 for Sunday
 *
 * SL7.04 57 87483 Hcl-chantar Thu Jun 02 01:13:52 2005
 * Invoices will not print if there is split commission
 * Issue 87483:
 * Deleted the Primary Key condition from the temp table @TmpCommdue and also deleted the IF condition which was just before the INSERT statement of @TmpCommdue table.
 *
 * SL7.04 56 87387 Hcl-chantar Thu May 26 08:14:19 2005
 * Invoice will not print for Split Commission and same Sales Manager
 * Issue 87387:
 * Added the following IF condition:
 * IF NOT EXISTS(SELECT 1 FROM @TmpCommdue
 *    WHERE inv_num = @CommdueInvNum AND
 *    slsman = @CommdueSlsman)
 *
 * SL7.04 55 87146 Hcl-chantar Tue May 24 01:29:52 2005
 * Multiple Invoice Distributions created
 * Issue 87146:
 * Modified the code to create a single distribution for a single a/c like Sales.
 *
 * SL7.04 54 87147 Hcl-chantar Tue May 17 02:23:02 2005
 * Order invoicing Credit/Memo Unit code distributions incorrect
 * Issue 87147.
 *
 * SL7.04 53 87150 Coatper Fri May 06 11:14:05 2005
 * Wrong Sales account used on invoice distributions
 * Issue 87150 - Corrected sales and disc acct assignment logic.
 *
 * SL7.04 52 87121 Hcl-chantar Thu May 05 01:52:23 2005
 * Under certain conditions, invoice will not print if there was a shipment, unship and reship
 * Issue 87121:
 * Added  @CustomerPrintPackInv = 1 and @PackNum <> 0 and  @CustomerPrintPackInv = 1 and @PackNum = 0 as a condition in the IF statement.
 *
 * SL7.04 51 87121 Hcl-chantar Thu May 05 00:53:02 2005
 * Under certain conditions, invoice will not print if there was a shipment, unship and reship
 * Issue 87121:
 * Modified the IF condition for inserting records in the "@TmpPckitem" table.
 * Added an IF condition before inserting records in "@TmpSerial" table.
 *
 *
 * SL7.04 50 86904 Debmcw Wed Apr 20 17:10:38 2005
 * Account and unit codes set up in End User Type are ignored by order invoicing credit memo
 * 86904
 *
 * SL7.04 49 86899 Debmcw Fri Apr 15 16:42:47 2005
 * Unit code 2 for the first invoice is applied to all invoices printed during the same invoice generation.
 * 86899
 *
 * SL7.04 48 86834 Hcl-samujob Wed Apr 13 04:30:02 2005
 * Invoices for CO appearing on the Uninvoiced Packing Slip Report are not printing
 * Check in for Issue 86834. Modified code to insert record into the @TmpPckItem temp table.
 *
 * SL7.04 47 86678 Hcl-chantar Fri Apr 01 02:27:45 2005
 * Serial numbers are printing incorrectly on invoices
 * Issue 86678:
 * Added the following condition:
 * AND ((matltrack.track_link = @PackNum) OR (@PackNum = 0))
 *
 * SL7.04 46 86508 Hcl-sharpar Wed Mar 30 09:26:57 2005
 * Stub calls needed for French Localization
 * issue 86508
 * RS 1256
 *
 * SL7.04 45 86508 Hcl-sharpar Wed Mar 30 09:24:14 2005
 * Stub calls needed for French Localization
 * issue 86508
 * RS 1249
 *
 * SL7.04 44 86603 Hcl-chantar Wed Mar 23 01:59:38 2005
 * Credit memo will not print if second return does not return to stock
 * Issue 86603:
 * Deleted the line
 * GOTO EXIT_SP
 *
 * SL7.04 43 86557 Coatper Fri Mar 18 14:48:13 2005
 * Issue 86557 - Fixed problems with Credit Memos.
 *
 * SL7.04 42 86379 Coatper Thu Mar 10 10:32:03 2005
 * Less Previously Invoiced missing for Negative CO Lines
 * Issue 86379 - Changed to create "Less Previously Invoiced" inv_pro records for negative amounts as well as positive amounts.
 *
 * SL7.04 41 85966 Coatper Mon Feb 14 15:24:29 2005
 * Tax is being charged again on Final Invoice for Progressive Billings
 * Issue 85966 - Corrected logic that determines tax amounts for invoices when progressive billings are involved.  Also, changed logic to correctly update co field amounts.
 *
 * SL7.04 40 85007 Coatper Mon Feb 07 14:55:12 2005
 * Replication - Invoicing
 * Issue 85007 - Rewrote the SP to buffer up all transactions and do table insert/updates only at the end of the SP, with the goal of improving speed and reducing record locking/blocking.  Merged InvPostSp1Sp into InvPostSp.
 *
 */

CREATE PROCEDURE [dbo].[InvPostSp] (
  @InvType                 NCHAR(3)       = 'R'
, @InvCred                 NCHAR(1)       = 'I'
, @InvDate                 DateType       = NULL
, @StartCustomer           CustNumType    = NULL
, @EndCustomer             CustNumType    = NULL
, @StartOrderNum           CoNumType      = NULL
, @EndOrderNum             CoNumType      = NULL
, @StartLine               CoLineType     = NULL
, @EndLine                 CoLineType     = NULL
, @StartRelease            CoReleaseType  = NULL
, @EndRelease              CoReleaseType  = NULL
, @StartLastShipDate       DateType       = NULL
, @EndLastShipDate         DateType       = NULL
, @pMooreForms             nvarchar(1)    = 'N'
, @pNonDraftCust           FlagNYType     = 0
, @PackNum                 PackNumType    = 0
, @CheckShipItemActiveFlag FlagNYType     = 0
, @TInvNum                 InvNumType     = '0'   OUTPUT
, @StartInvNum             InvNumType     = NULL  OUTPUT
, @EndInvNum               InvNumType     = NULL  OUTPUT
, @Infobar                 InfobarType    = NULL  OUTPUT
, @BatchId                 BatchIdType
, @ProcessId               RowPointerType = NULL
, @InvoiceCount            int = 0 output
, @EDINoPaperInvoiceCount  int = 0 OUTPUT
, @StartPackNum            PackNumType    = NULL
, @EndPackNum              PackNumType    = NULL
, @CreateFromPackSlip      FlagNYType     = 0
, @CalledFrom              InfobarType    = NULL -- can be InvoiceBuilder or NULL           
, @InvoicBuilderProcessID  RowpointerType = NULL

) AS

   -- Check for existence of Generic External Touch Point routine (this section was generated by SpETPCodeSp and inserted by CallETPs.exe):
   IF OBJECT_ID(N'dbo.EXTGEN_InvPostSp') IS NOT NULL
   BEGIN
      DECLARE @EXTGEN_SpName sysname
      SET @EXTGEN_SpName = N'dbo.EXTGEN_InvPostSp'
      -- Invoke the ETP routine, passing in (and out) this routine's parameters:
      DECLARE @EXTGEN_Severity int
      EXEC @EXTGEN_Severity = @EXTGEN_SpName
         @InvType
         , @InvCred
         , @InvDate
         , @StartCustomer
         , @EndCustomer
         , @StartOrderNum
         , @EndOrderNum
         , @StartLine
         , @EndLine
         , @StartRelease
         , @EndRelease
         , @StartLastShipDate
         , @EndLastShipDate
         , @pMooreForms
         , @pNonDraftCust
         , @PackNum
         , @CheckShipItemActiveFlag
         , @TInvNum OUTPUT
         , @StartInvNum OUTPUT
         , @EndInvNum OUTPUT
         , @Infobar OUTPUT
         , @BatchId
         , @ProcessId
         , @InvoiceCount OUTPUT
         , @EDINoPaperInvoiceCount OUTPUT
         , @StartPackNum
         , @EndPackNum
         , @CreateFromPackSlip
         , @CalledFrom
         , @InvoicBuilderProcessID
 
      -- ETP routine can RETURN 1 to signal that the remainder of this standard routine should now proceed:
      IF @EXTGEN_Severity <> 1
         RETURN @EXTGEN_Severity
   END
   -- End of Generic External Touch Point code.
 
DECLARE
  @AmountToApply    AmountType
, @AmountToApply2   AmountType
, @AmountApplied    AmountType
, @BilledFor        AmountType
, @BilledFor2       AmountType
, @DPrice           CostPrcType
, @I                GenericNoType
, @LeftToApply      AmountType
, @OLvlDiscLineNet  CostPrcType
, @PartiallyApplied AmountType
, @QtyToInvoice     QtyUnitType
, @TProgBill        FlagNyType
, @TApp             AmountType
, @TCreditMemoCost  CostPrcType
, @TReturned        QtyUnitType
, @TQtyRemain       QtyUnitType
, @TLineNet         AmountType
, @TLineTot         AmountType
, @TEndSales        AcctType
, @TEndSalesUnit1   UnitCode1Type
, @TEndSalesUnit2   UnitCode2Type
, @TEndSalesUnit3   UnitCode3Type
, @TEndSalesUnit4   UnitCode4Type
, @TProgAcct        AcctType
, @TProgAcctUnit1   UnitCode1Type
, @TProgAcctUnit2   UnitCode2Type
, @TProgAcctUnit3   UnitCode3Type
, @TProgAcctUnit4   UnitCode4Type
, @TMatlCost        CostPrcType
, @TMatlShip        QtyPerType
, @TMatltype        LongListType
, @TStat            LongListType
, @TShipDate        CurrentDateType
, @TCoitemQty       QtyTotlType
, @TBalAdj          AmountType
, @TXInvProAmount   AmountType
, @TInvAmount       AmountType
, @TTaxablePrice                  DefaultCharType
, @TextLessPreviouslyInvoiced     WideTextType
, @TextBalance                    WideTextType
, @TaxInclDiscount      ListYesNoType
, @Tax1OnAmount         AmountType
, @Tax2OnAmount         AmountType
, @Tax1OnDiscAmount     AmountType
, @Tax2OnDiscAmount     AmountType
, @Tax1OnUndiscAmount   AmountType
, @Tax2OnUndiscAmount   AmountType
, @TotalTaxOnDiscAmount AmountType
, @DiscAmountInclTax    AmountType
, @DiscAmountInclTax2   AmountType
, @xAmount1             AmountType
, @BalAdj        AmountType
, @DAmt          AmountType
, @PrintFlag     FlagNyType
, @ResultAmt     AmountType
, @Severity      INT
, @TSubTotFull   AmountType
, @TDistSeq      GenericNoType
, @TSubTotal     AmountType
, @TDraftSeq     GenericNoType
, @TServCust     CustNumType
, @TAr           LongListType
, @TArCredit     ReferenceType
, @TOpen         LongListType
, @TCrMemo       LongListType
, @TInvLabel     LongListType
, @TSalesTax     AmountType
, @TSalesTax2    AmountType
, @TTaxSeq       GenericNoType
, @TDiscAmount   GenericDecimalType
, @TAdjPrice     GenericDecimalType
, @TCommBaseTot  GenericDecimalType
, @TCurSlsman    SlsmanType
, @TLoopCounter  GenericNoType
, @TCoLine       CoLineType
, @TCommCalc     GenericDecimalType
, @TCommBase     GenericDecimalType
, @TError        FlagNyType
, @TEndAr        AcctType
, @TEndArUnit1   UnitCode1Type
, @TEndArUnit2   UnitCode2Type
, @TEndArUnit3   UnitCode3Type
, @TEndArUnit4   UnitCode4Type
, @TEndDisc      AcctType
, @TEndDiscUnit1 UnitCode1Type
, @TEndDiscUnit2 UnitCode2Type
, @TEndDiscUnit3 UnitCode3Type
, @TEndDiscUnit4 UnitCode4Type
, @TRate         ExchRateType
, @TLastTran           InvNumType
, @ReleaseTmpTaxTables FlagNyType
, @SessionId           RowPointerType
, @TraceMsg            InfobarType
, @Count               INT
, @LinesPerDoc         INT
, @CurrLinesDoc        INT
, @LoopLinesDoc        INT
, @RowNum              INT
, @RecordsFound        INT
, @TCoItemPrice   AmountType
, @SavedState LongListType
, @IsPartialCommit ListYesNoType
, @BeginTranCount int
, @LinesSoFar int
, @AllOrdersLocalSite ListYesNoType
, @ProgressiveRoundingAmt AmtTotType
, @PckhdrCoNum     CoNumType
, @PckhdrPackNum   PackNumType
, @OnePackInv      FlagNyType
, @InvProExists ListYesNoType
, @NoProg ListYesNoType
, @AccumTax1 AmountType
, @AccumTax2 AmountType
, @TaxDiff AmountType
, @TmpTaxCalcRowPointer RowPointerType
, @ConvFactor UMConvFactorType
, @WholesalePrice AmountType
, @ConsumptionTaxHeaderLineMethod  JP_ConsumptionTaxHeaderLineMethodType
, @UseJPLineMethod  FlagNyType
, @LineMethodRefType RefType

DECLARE
  @ArinvRowPointer           RowPointerType
, @ArinvCustNum              CustNumType
, @ArinvInvNum               InvNumType
, @ArinvType                 ArinvTypeType
, @ArinvPostFromCo           ListYesNoType
, @ArinvCoNum                CoNumType
, @ArinvInvDate              DateType
, @ArinvTaxCode1             TaxCodeType
, @ArinvTaxCode2             TaxCodeType
, @ArinvTermsCode            TermsCodeType
, @ArinvAcct                 AcctType
, @ArinvAcctUnit1            UnitCode1Type
, @ArinvAcctUnit2            UnitCode2Type
, @ArinvAcctUnit3            UnitCode3Type
, @ArinvAcctUnit4            UnitCode4Type
, @ArinvRef                  ReferenceType
, @ArinvDescription          DescriptionType
, @ArinvExchRate             ExchRateType
, @ArinvUseExchRate          ListYesNoType
, @ArinvFixedRate            ListYesNoType
, @ArinvPayType              CustPayTypeType
, @ArinvDraftPrintFlag       ListYesNoType
, @ArinvDueDate              DateType
, @ArinvDiscDate             DateType
, @ArinvInvSeq               ArInvSeqType
, @ArinvSalesTax             AmountType
, @ArinvSalesTax2            AmountType
, @ArinvMiscCharges          AmountType
, @ArinvFreight              AmountType
, @ArinvAmount               AmountType
, @ArinvApprovalStatus       ListPendingApprovedRejectedType

, @ArinvdRowPointer          RowPointerType
, @ArinvdAmount              AmountType
, @ArinvdCustNum             CustNumType
, @ArinvdInvNum              InvNumType
, @ArinvdInvSeq              ArInvSeqType
, @ArinvdDistSeq             ArDistSeqType
, @ArinvdAcct                AcctType
, @ArinvdAcctUnit1           UnitCode1Type
, @ArinvdAcctUnit2           UnitCode2Type
, @ArinvdAcctUnit3           UnitCode3Type
, @ArinvdAcctUnit4           UnitCode4Type
, @ArinvdTaxSystem           TaxSystemType
, @ArinvdTaxCode             TaxCodeType
, @ArinvdTaxCodeE            TaxCodeType
, @ArinvdTaxBasis            AmountType
, @ArInvDateDay              WeekDayType
, @ArInvDueDateDay           WeekDayType
, @ArinvdRefType             RefTypeOType
, @ArinvdRefNum              CoNumType
, @ArinvdRefLineSuf          CoLineType
, @ArinvdRefRelease          CoReleaseType

, @ArparmsRowPointer         RowPointerType
, @ArparmsArAcct             AcctType
, @ArparmsArAcctUnit1        UnitCode1Type
, @ArparmsArAcctUnit2        UnitCode2Type
, @ArparmsArAcctUnit3        UnitCode3Type
, @ArparmsArAcctUnit4        UnitCode4Type
, @ArparmsSalesDiscAcct      AcctType
, @ArparmsSalesDiscAcctUnit1 UnitCode1Type
, @ArparmsSalesDiscAcctUnit2 UnitCode2Type
, @ArparmsSalesDiscAcctUnit3 UnitCode3Type
, @ArparmsSalesDiscAcctUnit4 UnitCode4Type
, @ArparmsMiscAcct           AcctType
, @ArparmsMiscAcctUnit1      UnitCode1Type
, @ArparmsMiscAcctUnit2      UnitCode2Type
, @ArparmsMiscAcctUnit3      UnitCode3Type
, @ArparmsMiscAcctUnit4      UnitCode4Type
, @ArparmsFreightAcct        AcctType
, @ArparmsFreightAcctUnit1   UnitCode1Type
, @ArparmsFreightAcctUnit2   UnitCode2Type
, @ArparmsFreightAcctUnit3   UnitCode3Type
, @ArparmsFreightAcctUnit4   UnitCode4Type
, @ArparmsProjAcct           AcctType
, @ArparmsProgAcct           AcctType
, @ArparmsProjAcctUnit1      UnitCode1Type
, @ArparmsProjAcctUnit2      UnitCode2Type
, @ArparmsProjAcctUnit3      UnitCode3Type
, @ArparmsProjAcctUnit4      UnitCode4Type
, @ArparmsProgAcctUnit1      UnitCode1Type
, @ArparmsProgAcctUnit2      UnitCode2Type
, @ArparmsProgAcctUnit3      UnitCode3Type
, @ArparmsProgAcctUnit4      UnitCode4Type

, @ArparmsNonInvAcct  AcctType       --For noninv items
, @ArparmsNonInvAcctUnit1   UnitCode1Type
, @ArparmsNonInvAcctUnit2   UnitCode2Type
, @ArparmsNonInvAcctUnit3   UnitCode3Type
, @ArparmsNonInvAcctUnit4   UnitCode4Type

, @ArparmUsePrePrintedForms  ListYesNoType
, @ArparmLinesPerInv         LinesPerDocType
, @ArparmLinesPerDM          LinesPerDocType
, @ArparmLinesPerCM          LinesPerDocType

, @ArtranRowPointer          RowPointerType
, @ArtranCustNum             CustNumType
, @ArtranInvNum              InvNumType

, @BankAddrRowPointer        RowPointerType
, @BankAddrBankNumber        BankNumberType
, @BankAddrAddr##1           AddressType
, @BankAddrAddr##2           AddressType
, @BankAddrBranchCode        BranchCodeType

, @CoShipRowPointer          RowPointerType
, @CoShipQtyInvoiced         QtyUnitType
, @CoShipQtyShipped          QtyUnitType
, @CoShipQtyReturned         QtyUnitType
, @CoShipShipDate            DateType
, @CoShipCost                CostPrcType
, @CoShipOrigInvoice         InvNumType
, @CoShipReasonText          FormEditorType
, @CoShipPackNum PackNumType

, @CustdrftRowPointer        RowPointerType

, @CustLcrRowPointer         RowPointerType
, @CustLcrShipValue          AmountType

, @CoSlsCommSlsman           SlsmanType
, @CoSlsCommRevPercent       CommPercentType
, @CoSlsCommCommPercent      CommPercentType
, @CoSlsCommCoLine           CoLineType

, @CommdueRowPointer         RowPointerType
, @CommdueInvNum             InvNumType
, @CommdueCoNum              CoNumType
, @CommdueSlsman             SlsmanType
, @CommdueCustNum            CustNumType
, @CommdueCommDue            AmountType
, @CommdueDueDate            DateType
, @CommdueCommCalc           AmountType
, @CommdueCommBase           AmountType
, @CommdueCommBaseSlsp       AmountType
, @CommdueSeq                CommdueSeqType
, @CommduePaidFlag           ListYesNoType
, @CommdueSlsmangr           SlsmanType
, @CommdueStat               CommdueStatusType
, @CommdueRef                ReferenceType
, @CommdueEmpNum             EmpNumType

, @CountryRowPointer         RowPointerType
, @CountryEcCode             EcCodeType

, @CoitemRowPointer          RowPointerType
, @CoitemCoNum               CoNumType
, @CoitemCoLine              CoLineType
, @CoitemCoRelease           CoReleaseType
, @CoitemQtyInvoiced         QtyUnitNoNegType
, @CoitemQtyShipped          QtyUnitNoNegType
, @CoitemItem                ItemType
, @CoitemShipDate            DateType
, @CoitemPrice               CostPrcType
, @CoitemDisc                LineDiscType
, @CoitemQtyOrdered          QtyUnitNoNegType
, @CoitemPrgBillTot          AmountType
, @CoitemPrgBillApp          AmountType
, @CoitemProcessInd          ProcessIndType
, @CoitemConsNum             ConsignmentsType
, @CoitemTaxCode1            TaxCodeType
, @CoitemTaxCode2            TaxCodeType
, @CoitemCustPo              CustPoType
, @CoitemQtyReturned         QtyUnitNoNegType
, @CoitemCost                CostPrcType
, @CoitemCgsTotal            AmountType
, @CoitemWhse                WhseType
, @CoitemRefType             RefTypeIJKPRTType
, @CoitemRefNum              JobPoProjReqTrnNumType
, @CoitemRefLineSuf          SuffixPoLineProjTaskReqTrnLineType
, @CoitemPriceConv           CostPrcType
, @CoitemUM                  UMType

, @CoRowPointer              RowPointerType
, @CoCustNum                 CustNumType
, @CoCustSeq                 CustSeqType
, @CoCoNum                   CoNumType
, @CoEndUserType             EndUserTypeType
, @CoTermsCode               TermsCodeType
, @CoShipCode                ShipCodeType
, @CoCustPo                  CustPoType
, @CoWeight                  WeightType
, @CoQtyPackages             PackagesType
, @CoDisc                    GenericDecimalType --OrderDiscType
, @CoDiscAmount              AmountType
, @CoDiscountType            ListAmountPercentType
, @CoPrice                   AmountType
, @CoAmount                  AmountType
, @CoFixedRate               ListYesNoType
, @CoExchRate                ExchRateType
, @CoUseExchRate             ListYesNoType
, @CoTaxCode1                TaxCodeType
, @CoTaxCode2                TaxCodeType
, @CoFrtTaxCode1             TaxCodeType
, @CoFrtTaxCode2             TaxCodeType
, @CoMscTaxCode1             TaxCodeType
, @CoMscTaxCode2             TaxCodeType
, @CoSlsman                  SlsmanType
, @CoMiscCharges             AmountType
, @CoFreight                 AmountType
, @CoPrepaidAmt              AmountType
, @CoPrepaidT                AmountType
, @CoMChargesT               AmountType
, @CoFreightT                AmountType
, @CoSalesTaxT               AmountType
, @CoSalesTaxT2              AmountType
, @CoSalesTax                AmountType
, @CoSalesTax2               AmountType
, @CoInvoiced                ListYesNoType
, @CoLcrNum                  LcrNumType
, @CoEdiType                 EdiTypeType
, @CoIncludeTaxInPrice       ListYesNoType
, @CoApplyToInvNum           InvNumType
, @CoOrigSite                SiteType

, @CoparmsDueOnPmt           AmountType
, @CoparmsRowPointer         RowPointerType
, @CoParmsUseAltPriceCalc    ListYesNoType

, @CurrencyRowPointer        RowPointerType
, @CurrencyCurrCode          CurrCodeType
, @CurrencyPlaces            DecimalPlacesType
, @CurrencyPlacesCp          DecimalPlacesType

, @CurrparmsCurrCode         CurrCodeType
, @CurrparmsRowPointer       RowPointerType

, @CustaddrRowPointer        RowPointerType
, @CustaddrState             StateType
, @CustaddrCurrCode          CurrCodeType
, @CustaddrCountry           CountryType

, @CustomerRowPointer        RowPointerType
, @CustomerCustType          CustTypeType
, @CustomerPayType           CustPayTypeType
, @CustomerDraftPrintFlag    ListYesNoType
, @CustomerCustBank          BankCodeType
, @CustomerCustNum           CustNumType
, @CustomerBankCode          BankCodeType
, @CustomerEdiCust           ListYesNoType
, @CustomerUseRevisionPayDays ListYesNoType
, @CustomerRevisionDay       WeekDayType
, @CustomerPayDay            WeekDayType
, @CustomerPrintPackInv      FlagNyType
, @CustomerOnePackInv        FlagNyType

, @CusttypeRowPointer        RowPointerType
, @CusttypeTaxablePrice      TaxablePriceType

, @CustTpPaperInv            ListYesNoType
, @DistacctRowPointer        RowPointerType
, @DistacctSalesAcct         AcctType
, @DistacctSaleDsAcct        AcctType
, @DistacctSalesAcctUnit1    UnitCode1Type
, @DistacctSalesAcctUnit2    UnitCode2Type
, @DistacctSalesAcctUnit3    UnitCode3Type
, @DistacctSalesAcctUnit4    UnitCode4Type
, @DistacctSaleDsAcctUnit1   UnitCode1Type
, @DistacctSaleDsAcctUnit2   UnitCode2Type
, @DistacctSaleDsAcctUnit3   UnitCode3Type
, @DistacctSaleDsAcctUnit4   UnitCode4Type

, @EndtypeRowPointer         RowPointerType
, @EndtypeArAcct             AcctType
, @EndtypeArAcctUnit1        UnitCode1Type
, @EndtypeArAcctUnit2        UnitCode2Type
, @EndtypeArAcctUnit3        UnitCode3Type
, @EndtypeArAcctUnit4        UnitCode4Type
, @EndtypeSalesDsAcct        AcctType
, @EndtypeSalesDsAcctUnit1   UnitCode1Type
, @EndtypeSalesDsAcctUnit2   UnitCode2Type
, @EndtypeSalesDsAcctUnit3   UnitCode3Type
, @EndtypeSalesDsAcctUnit4   UnitCode4Type
, @EndtypeSalesAcct          AcctType
, @EndtypeSalesAcctUnit1     UnitCode1Type
, @EndtypeSalesAcctUnit2     UnitCode2Type
, @EndtypeSalesAcctUnit3     UnitCode3Type
, @EndtypeSalesAcctUnit4     UnitCode4Type
, @EndtypeNonInvAcct         AcctType     --For Noninv item
, @EndtypeNonInvAcctUnit1    UnitCode1Type
, @EndtypeNonInvAcctUnit2    UnitCode2Type
, @EndtypeNonInvAcctUnit3    UnitCode3Type
, @EndtypeNonInvAcctUnit4    UnitCode4Type


, @InvHdrRowPointer          RowPointerType
, @InvHdrInvNum              InvNumType
, @InvHdrInvSeq              InvSeqType
, @InvHdrCustNum             CustNumType
, @InvHdrCustSeq             CustSeqType
, @InvHdrCoNum               CoNumType
, @InvHdrInvDate             DateType
, @InvHdrCost                AmountType
, @InvHdrTermsCode           TermsCodeType
, @InvHdrShipCode            ShipCodeType
, @InvHdrCustPo              CustPoType
, @InvHdrWeight              WeightType
, @InvHdrQtyPackages         PackagesType
, @InvHdrDisc                GenericDecimalType --OrderDiscType
, @InvHdrBillType            BillingTypeType
, @InvHdrState               StateType
, @InvHdrExchRate            ExchRateType
, @InvHdrUseExchRate         ListYesNoType
, @InvHdrTaxCode1            TaxCodeType
, @InvHdrTaxCode2            TaxCodeType
, @InvHdrFrtTaxCode1         TaxCodeType
, @InvHdrFrtTaxCode2         TaxCodeType
, @InvHdrMscTaxCode1         TaxCodeType
, @InvHdrMscTaxCode2         TaxCodeType
, @InvHdrTaxDate             DateType
, @InvHdrShipDate            DateType
, @InvHdrSlsman              SlsmanType
, @InvHdrEcCode              EcCodeType
, @InvHdrMiscCharges         AmountType
, @InvHdrFreight             AmountType
, @InvHdrPrice               AmountType
, @InvHdrPrepaidAmt          AmountType
, @InvHdrTotCommDue          AmountType
, @InvHdrCommCalc            AmountType
, @InvHdrCommBase            AmountType
, @InvHdrCommDue             AmountType
, @InvHdrMiscAcct            AcctType
, @InvHdrMiscAcctUnit1       UnitCode1Type
, @InvHdrMiscAcctUnit2       UnitCode2Type
, @InvHdrMiscAcctUnit3       UnitCode3Type
, @InvHdrMiscAcctUnit4       UnitCode4Type
, @InvHdrFreightAcct         AcctType
, @InvHdrFreightAcctUnit1    UnitCode1Type
, @InvHdrFreightAcctUnit2    UnitCode2Type
, @InvHdrFreightAcctUnit3    UnitCode3Type
, @InvHdrFreightAcctUnit4    UnitCode4Type
, @InvHrdAcct                AcctType
, @InvHrdAcctUnit1           UnitCode1Type
, @InvHrdAcctUnit2           UnitCode2Type
, @InvHrdAcctUnit3           UnitCode3Type
, @InvHrdAcctUnit4           UnitCode4Type

, @InvItemRowPointer       RowPointerType
, @InvItemInvNum             InvNumType
, @InvItemInvSeq             InvSeqType
, @InvItemInvLine            InvLineType
, @InvItemCoNum              CoNumType
, @InvItemCoLine             CoLineType
, @InvItemCoRelease          CoReleaseType
, @InvItemItem               ItemType
, @InvItemDisc               LineDiscType
, @InvItemPrice              CostPrcType
, @InvItemProcessInd         ProcessIndType
, @InvItemConsNum            ConsignmentsType
, @InvItemTaxCode1           TaxCodeType
, @InvItemTaxCode2           TaxCodeType
, @InvItemTaxDate            DateType
, @InvItemCustPo             CustPoType
, @InvItemQtyInvoiced        QtyUnitType
, @InvItemCost               CostPrcType
, @InvItemSalesAcct          AcctType
, @InvItemSalesAcctUnit1     UnitCode1Type
, @InvItemSalesAcctUnit2     UnitCode2Type
, @InvItemSalesAcctUnit3     UnitCode3Type
, @InvItemSalesAcctUnit4     UnitCode4Type
, @InvItemOrigInvoice      InvNumType
, @InvItemReasonText      FormEditorType
, @InvItemPriceConv CostPrcType
, @InvItemQtyInvoicedConv QtyUnitType
, @InvItemExciseTaxPercent   ExciseTaxPercentType

, @InvparmsPlacesQtyUnit DecimalPlacesType

, @InvProRowPointer          RowPointerType
, @InvProInvNum              InvNumType
, @InvProCoNum               CoNumType
, @InvProCoLine              CoLineType
, @InvProSeq                 InvProSeqType
, @InvProAmount              AmountType
, @InvProDescription         DescriptionType
, @InvProApplied             ListYesNoType

, @InvStaxInvNum             InvNumType
, @InvStaxInvSeq             InvSeqType
, @InvStaxSeq                StaxSeqType
, @InvStaxTaxCode            TaxCodeType
, @InvStaxSalesTax           AmountType
, @InvStaxStaxAcct           AcctType
, @InvStaxStaxAcctUnit1      UnitCode1Type
, @InvStaxStaxAcctUnit2      UnitCode2Type
, @InvStaxStaxAcctUnit3      UnitCode3Type
, @InvStaxStaxAcctUnit4      UnitCode4Type
, @InvStaxInvDate            DateType
, @InvStaxCustNum            CustNumType
, @InvStaxCustSeq            CustSeqType
, @InvStaxTaxBasis           AmountType
, @InvStaxTaxSystem          TaxSystemType
, @InvStaxTaxRate            TaxRateType
, @InvStaxTaxJur             TaxJurType
, @InvStaxTaxCodeE           TaxCodeType

, @ItemRowPointer            RowPointerType
, @ItemSerialTracked         ListYesNoType
, @ItemItem                  ItemType
, @ItemUWsPrice              CostPrcType
, @ItemProductCode           ProductCodeType
, @ItemSubjectToExciseTax    ListYesNoType
, @ItemExciseTaxPercent      ExciseTaxPercentType
            
, @MatltranRowPointer        RowPointerType
, @MatltranQty               QtyUnitType
, @MatltranCost              CostPrcType

, @ParmsSite                 SiteType
, @ParmsRowPointer           RowPointerType
, @ParmsEcReporting          ListYesNoType
, @ParmsCountry              CountryType

, @ProdcodeRowPointer        RowPointerType
, @ProdcodeUnit              UnitCode2Type

, @ProgbillRowPointer        RowPointerType
, @ProgbillBillAmt           AmountType
, @ProgbillInvcFlag          ProgBillInvoiceFlagType

, @SerialRowPointer          RowPointerType
, @SerialInvNum              InvNumType

, @SlsmanRowPointer          RowPointerType
, @SlsmanSlsman              SlsmanType
, @SlsmanSlsmangr            SlsmanType
, @SlsmanRefNum              EmpVendNumType

, @TaxparmsRowPointer        RowPointerType
, @TaxparmsLastTaxReport1    DateType
, @TaxparmsCashRound         CashRoundingFactorType
, @TaxparmsLastSsdReport     DateType

, @TermsRowPointer           RowPointerType
, @TermsDueDays              DueDaysType
, @TermsProxCode             ProxCodeType
, @TermsProxDay              ProxDayType
, @TermsUseMultiDueDates     ListYesNoType
, @TermsCashOnly             ListYesNoType
, @TermsProxMonthToForward       ProxMonthToForwardType
, @TermsCutoffDay                CutoffDayType
, @TermsDiscDays                 DiscDaysType
, @TermsHolidayOffsetMethod      HolidayOffsetMethodType    
, @TermsProxDiscMonthToForward   ProxDiscMonthToForwardType
, @TermsProxDiscDay              ProxDiscDayType

, @XCountryRowPointer        RowPointerType
, @XCountryEcCode            EcCodeType

, @XInvProRowPointer         RowPointerType
, @XInvProAmount             AmountType

, @TmpArinvCustNum           CustNumType
, @TmpArinvInvNum            InvNumType
, @TmpArinvInvSeq            ArInvSeqType
, @TmpArinvInvDate           DateType
, @TmpArinvTermsCode         TermsCodeType
, @DomCurrencyPlaces         DecimalPlacesType
, @SSSVTXInvItemRowPointer   RowPointerType  --SSS VTX
, @TaxBaseAmountToApply      AmountType 
, @TaxBaseTLineTot           AmountType

, @ArparmsSurchargeAcct      AcctType
, @ArparmsSurchargeAcctUnit1 UnitCode1Type
, @ArparmsSurchargeAcctUnit2 UnitCode2Type
, @ArparmsSurchargeAcctUnit3 UnitCode3Type
, @ArparmsSurchargeAcctUnit4 UnitCode4Type

, @RuleEffectDate            DateType
, @ItemContent               ItemContentType
, @Item                      ItemType
, @RefType                   RefType
, @RefNum                    EmpJobCoPoRmaProjPsTrnNumType
, @RefLine                   CoLineSuffixPoLineProjTaskRmaTrnLineType
, @RefRelease                CoReleaseOperNumPoReleaseType
, @SurchargeSeq              SurchargeSeqType
, @LineSurcharge             AmountType
, @InvSurcharge              AmountType
, @CoSurcharge               AmountType
, @ArparmsSurchargeFactor    SurchargeFactorType
, @EndtypeSurchargeAcct      AcctType
, @EndtypeSurchargeAcctUnit1 UnitCode1Type
, @EndtypeSurchargeAcctUnit2 UnitCode2Type
, @EndtypeSurchargeAcctUnit3 UnitCode3Type
, @EndtypeSurchargeAcctUnit4 UnitCode4Type

, @DistacctSurchargeAcct         AcctType
, @DistacctSurchargeAcctUnit1    UnitCode1Type
, @DistacctSurchargeAcctUnit2    UnitCode2Type
, @DistacctSurchargeAcctUnit3    UnitCode3Type
, @DistacctSurchargeAcctUnit4    UnitCode4Type

, @SurchargeAcct               AcctType
, @SurchargeAcctUnit1          UnitCode1Type
, @SurchargeAcctUnit2          UnitCode2Type
, @SurchargeAcctUnit3          UnitCode3Type
, @SurchargeAcctUnit4          UnitCode4Type

DECLARE
  @TInvHdrRowPointer  RowPointerType
, @TInvHdrInvNum      InvNumType
, @TInvHdrInvSeq      InvSeqType
, @TInvHdrInvDate     DateType
, @TInvHdrPrice       AmountType
, @TInvHdrPrepaidAmt  AmountType
, @TInvHdrFreight     AmountType
, @TInvHdrMiscCharges AmountType
, @TCRMemoTaxAmt      AmountType
, @TCRMemoSum         AmountType
, @OInvHdrRowpointer  RowPointerType
, @OInvHdrInvNum      InvNumType
, @OInvHdrInvSeq      InvSeqType
, @OInvHdrPrice       AmountType
, @OInvHdrPrepaidAmt  AmountType
, @OInvHdrFreight     AmountType
, @OInvHdrMiscCharges AmountType
, @OTaxAmt            AmountType
, @OInvSum            AmountType
, @TPerCent           GenericDecimalType
, @LocatorVar         INT
, @PrevCoNum          CoNumType

, @NonInventoryItem        FlagNyType --For Noninv item
, @CoitemNonInvAcct        AcctType
, @CoitemNonInvAcctUnit1   UnitCode1Type
, @CoitemNonInvAcctUnit2   UnitCode2Type
, @CoitemNonInvAcctUnit3   UnitCode3Type
, @CoitemNonInvAcctUnit4   UnitCode4Type

, @CoCustShipmentApprovalRequired FlagNyType

, @BuilderInvOrigSite      SiteType
, @BuilderInvNum           BuilderInvNumType

, @PromotionCode           PromotionCodeType
, @RebateType              ListAmountPercentType
, @Rebatenps               RebateNumberOfPeriodsType

, @CustType                CustTypeType
, @CorpCust                CustNumType
, @Slsman                  SlsmanType
, @EndUserType             EndUserTypeType
, @CustNum                 CustNumType
, @CustSeq                 CustSeqType
, @ProductCode             ProductCodeType
, @CampaignID              CampaignIDType
, @Deferacct               AcctType
, @DeferacctUnit1          UnitCode1Type
, @DeferacctUnit2          UnitCode2Type
, @DeferacctUnit3          UnitCode3Type
, @DeferacctUnit4          UnitCode4Type
, @ArparmsDeferacct        AcctType
, @ArparmsDeferacctUnit1   UnitCode1Type
, @ArparmsDeferacctUnit2   UnitCode2Type
, @ArparmsDeferacctUnit3   UnitCode3Type
, @ArparmsDeferacctUnit4   UnitCode4Type
, @ProAmount               AmountType
, @SumProAmount            AmountType
, @RebateRedemptionRate    ExchRateType
, @PaymentMethod           PaymentMethodType
, @ExpDate                 DateType
, @FiscalYear              FiscalYearType
, @Period                  int
, @PDate                   DateType
, @FieldLabel	            FormNameOrCaptionType
, @PromptMsg	            InfobarType
, @PromptButtons	         Infobar
, @RebateFairValue         RebateFairValueType
, @RebateFairValueType     ListAmountPercentType
, @DEarnedRebateAmount     AmountType

DECLARE @TmpArinv TABLE (
     cust_num                CustNumType
   , inv_num                 InvNumType
   , inv_seq                 ArInvSeqType
   , type                    ArinvTypeType
   , post_from_co            ListYesNoType
   , co_num                  CoNumType
   , inv_date                DateType
   , tax_code1               TaxCodeType
   , tax_code2               TaxCodeType
   , terms_code              TermsCodeType
   , acct                    AcctType
   , acct_unit1              UnitCode1Type
   , acct_unit2              UnitCode2Type
   , acct_unit3              UnitCode3Type
   , acct_unit4              UnitCode4Type
   , ref                     ReferenceType
   , description             DescriptionType
   , exch_rate               ExchRateType
   , use_exch_rate           ListYesNoType
   , fixed_rate              ListYesNoType
   , pay_type                CustPayTypeType
   , draft_print_flag        ListYesNoType
   , due_date                DateType
   , sales_tax               AmountType
   , sales_tax_2             AmountType
   , misc_charges            AmountType
   , freight                 AmountType
   , amount                  AmountType
   , approval_status         ListPendingApprovedRejectedType
   , include_tax_in_price    ListYesNoType
   , apply_to_inv_num        InvNumType
   , RowPointer              RowPointerType PRIMARY KEY
   , terms_use_multiDueDates tinyint
   )
   
 DECLARE @Surcharges TABLE
    (
      ItemContent         ItemContentType  
     ,CurrencyCode        CurrCodeType
     ,BasePrice           CostPrcType  
     ,DomPrice            CostPrcType   
     ,UM                  UMType  
     ,ItemContentFactor   ItemContentFactorType  
     ,ExchangeName        ExchangeNameType  
     ,Description         DescriptionType  
     ,Surcharge           CostPrcType 
    )
DECLARE
   @disc_amount AmountType

IF OBJECT_ID ('tempdb..#TmpInvHdr') IS NULL
     SELECT
     @InvHdrInvNum AS inv_num
   , @InvHdrInvSeq AS inv_seq
   , @InvHdrCustNum AS cust_num
   , @InvHdrCustSeq AS cust_seq
   , @InvHdrCoNum AS co_num
   , @InvHdrInvDate AS inv_date
   , @InvHdrTermsCode AS terms_code
   , @InvHdrShipCode AS ship_code
   , @InvHdrCustPo AS cust_po
   , @InvHdrWeight AS weight
   , @InvHdrQtyPackages AS qty_packages
   , @InvHdrDisc AS disc
   , @InvHdrBillType AS bill_type
   , @InvHdrState AS state
   , @InvHdrExchRate AS exch_rate
   , @InvHdrUseExchRate AS use_exch_rate
   , @InvHdrTaxCode1 AS tax_code1
   , @InvHdrTaxCode2 AS tax_code2
   , @InvHdrFrtTaxCode1 AS frt_tax_code1
   , @InvHdrFrtTaxCode2 AS frt_tax_code2
   , @InvHdrMscTaxCode1 AS msc_tax_code1
   , @InvHdrMscTaxCode2 AS msc_tax_code2
   , @InvHdrTaxDate AS tax_Date
   , @InvHdrShipDate AS ship_date
   , @InvHdrSlsman AS slsman
   , @InvHdrEcCode AS ec_code
   , @InvHdrMiscCharges AS misc_charges
   , @InvHdrFreight AS freight
   , @InvHdrPrice AS price
   , @InvHdrPrepaidAmt AS prepaid_amt
   , @InvHdrTotCommDue AS tot_comm_due
   , @InvHdrCommCalc AS comm_calc
   , @InvHdrCommBase AS comm_base
   , @InvHdrCommDue AS comm_due
   , @InvHdrMiscAcct AS misc_acct
   , @InvHdrMiscAcctUnit1 AS misc_acct_unit1
   , @InvHdrMiscAcctUnit2 AS misc_acct_unit2
   , @InvHdrMiscAcctUnit3 AS misc_acct_unit3
   , @InvHdrMiscAcctUnit4 AS misc_acct_unit4
   , @InvHdrFreightAcct AS freight_acct
   , @InvHdrFreightAcctUnit1 AS freight_acct_unit1
   , @InvHdrFreightAcctUnit2 AS freight_acct_unit2
   , @InvHdrFreightAcctUnit3 AS freight_acct_unit3
   , @InvHdrFreightAcctUnit4 AS freight_acct_unit4
   , @InvHdrCost AS cost
   , @InvHdrRowPointer AS RowPointer
   , @CurrencyCurrCode AS curr_code
   , @CurrencyPlaces AS curr_places
   , @CustomerEdiCust AS edi_cust
   , @disc_amount AS disc_amount
   , @CustTpPaperInv AS cust_tp_paper_invoice
     INTO #TmpInvHdr
     WHERE 1=2
     create UNIQUE index TmpInvHdrInvNum on #TmpInvHdr (inv_num)
     create UNIQUE index TmpInvHdrRowPointer on #TmpInvHdr (RowPointer)
   
DECLARE @TmpInvPro TABLE (
     inv_num                 InvNumType
   , inv_seq                 InvSeqType
   , co_num                  CoNumType
   , co_line                 CoLineType
   , seq                     InvProSeqType
   , amount                  AmountType
   , description             DescriptionType
   , applied                 ListYesNoType
   , new                     tinyint
   , RowPointer              RowPointerType PRIMARY KEY
   )

DECLARE @arinvd TABLE(
           cust_num    CustNumType
         , inv_num     InvNumType
         , inv_seq     ArInvSeqType
         , dist_seq    ArDistSeqType
         , amount      AmountType
         , acct        AcctType
         , acct_unit1  UnitCode1Type
         , acct_unit2  UnitCode2Type
         , acct_unit3  UnitCode3Type
         , acct_unit4  UnitCode4Type
         , tax_code    TaxCodeType
         , tax_code_e  TaxCodeType
         , tax_system  TaxSystemType
         , tax_basis   AmountType
         , new         TINYINT
         , RowPointer  RowPointerType
      )

DECLARE @TmpArinvd TABLE (
     cust_num                CustNumType
   , inv_num                 InvNumType
   , inv_seq                 ArInvSeqType
   , dist_seq                ArDistSeqType
   , acct                    AcctType
   , acct_unit1              UnitCode1Type
   , acct_unit2              UnitCode2Type
   , acct_unit3              UnitCode3Type
   , acct_unit4              UnitCode4Type
   , ref_type                RefTypeOType
   , ref_num                 CoNumType
   , ref_line_suf            CoLineType
   , ref_release             CoReleaseType
   , amount                  AmountType
   , tax_system              TaxSystemType
   , tax_code                TaxCodeType
   , tax_code_e              TaxCodeType
   , tax_basis               AmountType
   , RowPointer              RowPointerType PRIMARY KEY
   , new                     tinyint
   UNIQUE(cust_num, inv_num, inv_seq, acct, dist_seq)
   )

IF OBJECT_ID ('tempdb..#TmpInvItem') IS NULL
     SELECT
     @InvItemInvNum AS inv_num
   , @InvItemInvSeq AS inv_seq
   , @InvItemInvLine AS inv_line
   , @InvItemCoNum AS co_num
   , @InvItemCoLine AS co_line
   , @InvItemCoRelease AS co_release
   , @InvItemItem AS item
   , @InvItemDisc AS disc
   , @InvItemPrice AS price
   , @InvItemProcessInd AS process_ind
   , @InvItemConsNum AS cons_num
   , @InvItemTaxCode1 AS tax_code1
   , @InvItemTaxCode2 AS tax_code2
   , @InvItemTaxDate AS tax_date
   , @InvItemCustPo AS cust_po
   , @InvItemQtyInvoiced AS qty_invoiced
   , @InvItemCost AS cost
   , @InvItemSalesAcct AS sales_acct
   , @InvItemSalesAcctUnit1 AS sales_acct_unit1
   , @InvItemSalesAcctUnit2 AS sales_acct_unit2
   , @InvItemSalesAcctUnit3 AS sales_acct_unit3
   , @InvItemSalesAcctUnit4 AS sales_acct_unit4
   , @InvItemOrigInvoice AS orig_inv_num
   , @InvItemReasonText AS reason_text
   , @InvItemExciseTaxPercent AS excise_tax_percent
   , @InvItemRowPointer AS rowpointer
     INTO #TmpInvItem
     WHERE 1=2
     create unique index TmpInvItemInvNumSeqLine on #TmpInvItem (inv_num, inv_seq, inv_line, co_num, co_line, co_release)

DECLARE  @inv_stax TABLE(
           inv_num         InvNumType
         , inv_seq         InvSeqType
         , seq             StaxSeqType
         , tax_code        TaxCodeType
         , sales_tax       AmountType
         , stax_acct       AcctType
         , stax_acct_unit1 UnitCode1Type
         , stax_acct_unit2 UnitCode2Type
         , stax_acct_unit3 UnitCode3Type
         , stax_acct_unit4 UnitCode4Type
         , inv_date        DateType
         , cust_num        CustNumType
         , cust_seq        CustSeqType
         , tax_basis       AmountType
         , tax_system      TaxSystemType
         , tax_rate        TaxRateType
         , tax_jur         TaxJurType
         , tax_code_e      TaxCodeType
      )

DECLARE @TmpInvStax TABLE (
     inv_num                 InvNumType
   , inv_seq                 InvSeqType
   , seq                     StaxSeqType
   , tax_code                TaxCodeType
   , sales_tax               AmountType
   , stax_acct               AcctType
   , stax_acct_unit1         UnitCode1Type
   , stax_acct_unit2         UnitCode2Type
   , stax_acct_unit3         UnitCode3Type
   , stax_acct_unit4         UnitCode4Type
   , inv_date                DateType
   , cust_num                CustNumType
   , cust_seq                CustSeqType
   , tax_basis               AmountType
   , tax_system              TaxSystemType
   , tax_rate                TaxRateType
   , tax_jur                 TaxJurType
   , tax_code_e              TaxCodeType
   PRIMARY KEY (inv_num, inv_seq, seq)
   )

DECLARE @TmpCommdue TABLE (
     inv_num                 InvNumType
   , co_num                  CoNumType
   , slsman                  SlsmanType
   , cust_num                CustNumType
   , comm_due                AmountType
   , due_date                DateType
   , comm_calc               AmountType
   , comm_base               AmountType
   , comm_base_slsp          AmountType
   , seq                     CommdueSeqType
   , paid_flag               ListYesNoType
   , slsmangr                SlsmanType
   , stat                    CommdueStatusType
   , ref                     ReferenceType
   , emp_num                 EmpNumType
   )

DECLARE @TmpCustdrft TABLE (
     cust_num                CustNumType
   , inv_date                DateType
   , payment_due_date        DateType
   , amount                  AmountType
   , exch_rate               ExchRateType
   , stat                    CustdrftStatusType
   , inv_num                 InvNumType
   , co_num                  CoNumType
   , bank_code               BankCodeType
   , cust_bank               BankCodeType
   , bank_number             BankNumberType
   , bank_addr##1            AddressType
   , bank_addr##2            AddressType
   , branch_code             BranchCodeType
   , print_flag              ListYesNoType
   , escalation_cntr         CustDraftEscalationType
   , RowPointer              RowPointerType PRIMARY KEY
   )

DECLARE @TmpCoShip TABLE (
     qty_invoiced            QtyUnitType
   , qty_returned            QtyUnitType
   , upd_del_flag            nvarchar(1)
   , RowPointer              RowPointerType
   PRIMARY KEY(RowPointer, upd_del_flag)
   )

DECLARE @TmpPckitem TABLE (
     inv_num                 InvNumType
   , RowPointer              RowPointerType PRIMARY KEY
   )

DECLARE @TmpSerial TABLE (
     item                    ItemType
   , ser_num                 SerNumType
   , inv_num                 InvNumType
   PRIMARY KEY (item, ser_num)
   )

DECLARE @TmpProgbill TABLE (
     RowPointer              RowPointerType PRIMARY KEY
   , co_num                  CoNumType
   , co_line                 CoLineType
   , invc_flag               ProgBillInvoiceFlagType
   , seq                     ProgBillSeqType
   UNIQUE(co_num, co_line, seq)
   )

DECLARE @TmpItem TABLE (
     last_inv                DateType
   , RowPointer              RowPointerType PRIMARY KEY
   )

DECLARE @TmpItemwhse TABLE (
     RowPointer              RowPointerType PRIMARY KEY
   , item                    ItemType
   , whse                    WhseType
   , sales_ptd               AmountType
   , sales_ytd               AmountType
   UNIQUE(item, whse)
   )

DECLARE @TmpCoitem TABLE (
     ship_date               DateType
   , prg_bill_app            AmountType
   , qty_invoiced            QtyUnitNoNegType
   , qty_returned            QtyUnitNoNegType
   , RowPointer              RowPointerType PRIMARY KEY
   )

DECLARE @TmpSlsman TABLE (
     sales_ytd               AmountType
   , sales_ptd               AmountType
   , RowPointer              RowPointerType PRIMARY KEY
   )

DECLARE @TmpCo TABLE (
     prepaid_t               AmountType
   , m_charges_t             AmountType
   , freight_t               AmountType
   , sales_tax_t             AmountType
   , sales_tax_t2            AmountType
   , misc_charges            AmountType
   , sales_tax               AmountType
   , sales_tax_2             AmountType
   , freight                 AmountType
   , invoiced                ListYesNoType
   , prepaid_amt             AmountType
   , RowPointer              RowPointerType PRIMARY KEY
   )

DECLARE @TmpCustLcr TABLE (
     ship_value              AmountType
   , RowPointer              RowPointerType PRIMARY KEY
   )


declare @SarbWrt table (
  item         ItemType
, inv_date     DateType
, price        AmtTotType
, qty_invoiced QtyTotlType
primary key (item, inv_date)
)

declare @CoList table (
  co_num   CoNumType
, pack_num PackNumType
)

declare @CoListPack table (
  co_num   CoNumType
, pack_num PackNumType
primary key (co_num, pack_num)
)

declare @SerialTable table (
  item    ItemType
, ser_num SerNumType
, qty int
)

-- Init Passed Parameters
SET @Infobar       = NULL
SET @StartInvNum   = '0'
SET @EndInvNum     = '0'

-- Init Local Values

SET @Severity      = 0
SET @RecordsFound  = 0
SET @PrintFlag     = 0
SET @ResultAmt     = 0
SET @TSubTotFull   = 0
SET @TDistSeq      = 0
SET @TSubTotal     = 0
SET @TDraftSeq     = 0
SET @TServCust     = NULL
SET @TAr           = NULL
SET @TArCredit     = NULL
SET @TOpen         = NULL
SET @TCrMemo       = NULL
SET @TInvLabel     = NULL
SET @TSalesTax     = 0
SET @TSalesTax2    = 0
SET @TTaxSeq       = 0
SET @TDiscAmount   = 0
SET @TAdjPrice     = 0
SET @TCommBaseTot  = 0
SET @TCurSlsman    = NULL
SET @TLoopCounter  = 0
SET @TCoLine       = 0
SET @TCommCalc     = 0
SET @TCommBase     = 0
SET @TError        = 0
SET @TRate         = 0
SET @TLastTran     = '0'
SET @TCoItemPrice  = 0
set @AllOrdersLocalSite = 1
SET @LocatorVar    = 0
SET @LinesPerDoc   = 0
SET @PrevCoNum     = NULL
SET @NonInventoryItem = 0

SET @CoCustShipmentApprovalRequired = NULL

SET @TAr       = dbo.GetLabel('@!ARI') -- "ARI"
SET @TArCredit = dbo.GetLabel('@!ARCOPEN') -- "ARC OPEN"
SET @TInvLabel = dbo.GetLabel('@inv_stax.inv_num')
SET @TextLessPreviouslyInvoiced = dbo.StringOf('@!LessPreviouslyInvoiced')
SET @TextBalance = dbo.StringOf('@!bal')

SET @SessionId = dbo.SessionIDSp()

--EXEC SLDevEnv_App.dbo.SQLTraceSp 'InvPostSp: Start', 'thoblo'
SET @TOpen = dbo.GetLabel('@CapitalOPEN')

SET @ArparmsRowPointer              = NULL
SET @ArparmsArAcct                  = NULL
SET @ArparmsArAcctUnit1             = NULL
SET @ArparmsArAcctUnit2             = NULL
SET @ArparmsArAcctUnit3             = NULL
SET @ArparmsArAcctUnit4             = NULL
SET @ArparmsSalesDiscAcct           = NULL
SET @ArparmsSalesDiscAcctUnit1      = NULL
SET @ArparmsSalesDiscAcctUnit2      = NULL
SET @ArparmsSalesDiscAcctUnit3      = NULL
SET @ArparmsSalesDiscAcctUnit4      = NULL
SET @ArparmsMiscAcct                = NULL
SET @ArparmsMiscAcctUnit1           = NULL
SET @ArparmsMiscAcctUnit2           = NULL
SET @ArparmsMiscAcctUnit3           = NULL
SET @ArparmsMiscAcctUnit4           = NULL
SET @ArparmsFreightAcct             = NULL
SET @ArparmsFreightAcctUnit1        = NULL
SET @ArparmsFreightAcctUnit2        = NULL
SET @ArparmsFreightAcctUnit3        = NULL
SET @ArparmsFreightAcctUnit4        = NULL
SET @ArparmsRowPointer              = NULL
SET @ArparmsProjAcct                = NULL
SET @ArparmsProgAcct                = NULL
SET @ArparmsProjAcctUnit1           = NULL
SET @ArparmsProjAcctUnit2           = NULL
SET @ArparmsProjAcctUnit3           = NULL
SET @ArparmsProjAcctUnit4           = NULL
SET @ArparmsProgAcctUnit1           = NULL
SET @ArparmsProgAcctUnit2           = NULL
SET @ArparmsProgAcctUnit3           = NULL
SET @ArparmsProgAcctUnit4           = NULL
SET @ArparmsNonInvAcct              = NULL
SET @ArparmsNonInvAcctUnit1         = NULL
SET @ArparmsNonInvAcctUnit2         = NULL
SET @ArparmsNonInvAcctUnit3         = NULL
SET @ArparmsNonInvAcctUnit4         = NULL

SET @ArparmsSurchargeFactor         = NULL
SET @ArparmsSurchargeAcct           = NULL
SET @ArparmsSurchargeAcctUnit1      = NULL
SET @ArparmsSurchargeAcctUnit2      = NULL
SET @ArparmsSurchargeAcctUnit3      = NULL
SET @ArparmsSurchargeAcctUnit4      = NULL

SELECT
     @ArparmsRowPointer              = arparms.RowPointer
   , @ArparmsArAcct                  = arparms.ar_acct
   , @ArparmsArAcctUnit1             = arparms.ar_acct_unit1
   , @ArparmsArAcctUnit2             = arparms.ar_acct_unit2
   , @ArparmsArAcctUnit3             = arparms.ar_acct_unit3
   , @ArparmsArAcctUnit4             = arparms.ar_acct_unit4
   , @ArparmsSalesDiscAcct           = arparms.sales_disc_acct
   , @ArparmsSalesDiscAcctUnit1      = arparms.sales_disc_acct_unit1
   , @ArparmsSalesDiscAcctUnit2      = arparms.sales_disc_acct_unit2
   , @ArparmsSalesDiscAcctUnit3      = arparms.sales_disc_acct_unit3
   , @ArparmsSalesDiscAcctUnit4      = arparms.sales_disc_acct_unit4
   , @ArparmsMiscAcct                = arparms.misc_acct
   , @ArparmsMiscAcctUnit1           = arparms.misc_acct_unit1
   , @ArparmsMiscAcctUnit2           = arparms.misc_acct_unit2
   , @ArparmsMiscAcctUnit3           = arparms.misc_acct_unit3
   , @ArparmsMiscAcctUnit4           = arparms.misc_acct_unit4
   , @ArparmsFreightAcct             = arparms.freight_acct
   , @ArparmsFreightAcctUnit1        = arparms.freight_acct_unit1
   , @ArparmsFreightAcctUnit2        = arparms.freight_acct_unit2
   , @ArparmsFreightAcctUnit3        = arparms.freight_acct_unit3
   , @ArparmsFreightAcctUnit4        = arparms.freight_acct_unit4
   , @ArparmsProjAcct                = arparms.proj_acct
   , @ArparmsProgAcct                = arparms.prog_acct
   , @ArparmsProjAcctUnit1           = arparms.proj_acct_unit1
   , @ArparmsProjAcctUnit2           = arparms.proj_acct_unit2
   , @ArparmsProjAcctUnit3           = arparms.proj_acct_unit3
   , @ArparmsProjAcctUnit4           = arparms.proj_acct_unit4
   , @ArparmsProgAcctUnit1           = arparms.prog_acct_unit1
   , @ArparmsProgAcctUnit2           = arparms.prog_acct_unit2
   , @ArparmsProgAcctUnit3           = arparms.prog_acct_unit3
   , @ArparmsProgAcctUnit4           = arparms.prog_acct_unit4
   , @ArParmsNonInvAcct              = arparms.non_inv_acct
   , @ArparmsNonInvAcctUnit1         = arparms.non_inv_acct_unit1
   , @ArparmsNonInvAcctUnit2         = arparms.non_inv_acct_unit2
   , @ArparmsNonInvAcctUnit3         = arparms.non_inv_acct_unit3
   , @ArparmsNonInvAcctUnit4         = arparms.non_inv_acct_unit4 
   , @ArparmsDeferacct               = arparms.deferred_rev_acct
   , @ArparmsDeferacctUnit1          = arparms.deferred_rev_acct_unit1
   , @ArparmsDeferacctUnit2          = arparms.deferred_rev_acct_unit2
   , @ArparmsDeferacctUnit3          = arparms.deferred_rev_acct_unit3
   , @ArparmsDeferacctUnit4          = arparms.deferred_rev_acct_unit4
   , @ArparmsSurchargeFactor         = arparms.surcharge_factor
   , @ArparmsSurchargeAcct           = arparms.surcharge_acct
   , @ArparmsSurchargeAcctUnit1      = arparms.surcharge_acct_unit1
   , @ArparmsSurchargeAcctUnit2      = arparms.surcharge_acct_unit2
   , @ArparmsSurchargeAcctUnit3      = arparms.surcharge_acct_unit3
   , @ArparmsSurchargeAcctUnit4      = arparms.surcharge_acct_unit4
FROM arparms with (readuncommitted)

IF @ArparmsRowPointer IS NULL
BEGIN
   SET @Infobar = NULL
   EXEC @Severity = dbo.MsgAppSp @Infobar OUTPUT
                       , 'E=NoExist0'
                       , '@arparms'

   GOTO EXIT_SP
END

EXEC dbo.GetArparmLinesPerDocSp
   @ArparmUsePrePrintedForms OUTPUT,
   @ArparmLinesPerInv OUTPUT,
   @ArparmLinesPerDM OUTPUT,
   @ArparmLinesPerCM OUTPUT

IF @InvCred = 'I' AND @ArparmUsePrePrintedForms > 0
   SET @LinesPerDoc = @ArparmLinesPerInv
ELSE IF @InvCred = 'C' AND @ArparmUsePrePrintedForms > 0
   SET @LinesPerDoc = @ArparmLinesPerCM

SET @TaxparmsRowPointer     = NULL
SET @TaxparmsLastTaxReport1 = NULL
SET @TaxparmsCashRound      = 0
SET @TaxparmsLastSsdReport  = NULL

SELECT
     @TaxparmsRowPointer     = taxparms.RowPointer
   , @TaxparmsLastTaxReport1 = taxparms.last_tax_report_1
   , @TaxparmsCashRound      = taxparms.cash_round
   , @TaxparmsLastSsdReport = taxparms.last_ssd_report
FROM taxparms with (readuncommitted)

IF @TaxparmsRowPointer IS NULL
BEGIN
   SET @Infobar = NULL
   EXEC @Severity = dbo.MsgAppSp @Infobar OUTPUT
                       , 'E=NoExist0'
                       , '@taxparms'

   GOTO EXIT_SP
END

SET @ParmsRowPointer = NULL
SET @ParmsSite = NULL
SET @ParmsEcReporting = NULL
SET @ParmsCountry = NULL

SELECT
     @ParmsRowPointer = parms.RowPointer
   , @ParmsSite = parms.site
   , @ParmsEcReporting = parms.ec_reporting
   , @ParmsCountry = parms.country
FROM parms with (readuncommitted)

IF @ParmsRowPointer IS NULL
BEGIN
   SET @Infobar = NULL
   EXEC @Severity = dbo.MsgAppSp @Infobar OUTPUT
                       , 'E=NoExist0'
                       , '@parms'

   GOTO EXIT_SP
END

SET @XCountryRowPointer = NULL
SET @XCountryEcCode     = NULL

SELECT
     @XCountryRowPointer = country.RowPointer
   , @XCountryEcCode     = country.ec_code
FROM country with (readuncommitted)
WHERE country.country = @ParmsCountry

SET @CurrparmsRowPointer = NULL
SET @CurrparmsCurrCode = NULL

SELECT
     @CurrparmsRowPointer = currparms.RowPointer
   , @CurrparmsCurrCode = currparms.curr_code
FROM currparms with (readuncommitted)

SELECT TOP 1 @DomCurrencyPlaces = places
FROM currency with (readuncommitted)
WHERE currency.curr_code = @CurrparmsCurrCode

IF @CurrparmsRowPointer IS NULL
BEGIN
   SET @Infobar = NULL
   EXEC @Severity = dbo.MsgAppSp @Infobar OUTPUT
                       , 'E=NoExist0'
                       , '@currparms'

   GOTO EXIT_SP
END

SET @CoparmsRowPointer = NULL
SET @CoparmsDueOnPmt = 0
SELECT
     @CoparmsRowPointer = coparms.RowPointer
   , @CoparmsDueOnPmt = coparms.due_on_pmt
   , @CoParmsUseAltPriceCalc = coparms.use_alt_price_calc
FROM coparms with (readuncommitted)

IF @CoparmsRowPointer IS NULL
BEGIN
   SET @Infobar = NULL
   EXEC @Severity = dbo.MsgAppSp @Infobar OUTPUT
                       , 'E=NoExist0'
                       , '@coparms'

   GOTO EXIT_SP
END

SET @CoparmsDueOnPmt = ISNULL(@CoparmsDueOnPmt,0)

select @InvparmsPlacesQtyUnit = places_qty_unit
from invparms with (readuncommitted)

set @BeginTranCount = @@trancount
if @BeginTranCount = 0
   BEGIN TRANSACTION

set @LinesSoFar = 0

SET @StartCustomer = ISNULL(@StartCustomer, dbo.LowCharacter())
SET @EndCustomer = ISNULL(@EndCustomer, dbo.HighCharacter())
SET @StartOrderNum = ISNULL(@StartOrderNum, dbo.LowCharacter())
SET @EndOrderNum = ISNULL(@EndOrderNum, dbo.HighCharacter())
SET @CreateFromPackSlip = ISNULL(@CreateFromPackSlip, 0)

SET @BuilderInvOrigSite = NULL
SET @BuilderInvNum      = NULL
IF @CalledFrom = 'InvoiceBuilder'
BEGIN
   SELECT TOP 1
          @BuilderInvOrigSite = builder_inv_orig_site
        , @BuilderInvNum      = builder_inv_num
     FROM tmp_invoice_builder   
    WHERE process_ID = @InvoicBuilderProcessID      
END


if @CreateFromPackSlip = 1
begin
   set @InvCred = 'I'
   set @StartPackNum = ISNULL(@StartPackNum, dbo.LowAnyInt('PackNumType'))
   set @EndPackNum = ISNULL(@EndPackNum, dbo.HighAnyInt('PackNumType'))

   declare pck_hdrCrs1 cursor local static for
   select distinct co.co_num, customer.one_pack_inv
   from co with (readuncommitted)
      inner join customer with (readuncommitted) on
         customer.cust_num = co.cust_num
         and customer.cust_seq = 0
      inner join pck_hdr with (readuncommitted) on
         pck_hdr.co_num = co.co_num
         and pck_hdr.pack_num between @StartPackNum and @EndPackNum
         and pck_hdr.cust_num = co.cust_num
   where charindex(co.type, @InvType) > 0
   AND co.co_num between @StartOrderNum and @EndOrderNum
   and co.cust_num between @StartCustomer and @EndCustomer
   AND co.stat in ('O', 'S')
   and exists (select 1 from pckitem with (readuncommitted) where pckitem.pack_num = pck_hdr.pack_num
      and pckitem.inv_num is null)
   order by co.co_num

   open pck_hdrCrs1
   while @Severity = 0
   begin
      fetch pck_hdrCrs1 into
        @PckhdrCoNum
      , @OnePackInv

      if @@fetch_status != 0
         break

      if @OnePackInv = 0
      begin
         insert into @CoListPack
         select co_num, pack_num
         from pck_hdr with (readuncommitted)
         where pck_hdr.co_num = @PckhdrCoNum
         and pck_hdr.pack_num between @StartPackNum and @EndPackNum

         if @@rowcount < 1
            break

         insert into @CoList
         values(@PckhdrCoNum, 0)
      end
      else
      begin
         insert into @CoList
         select pck_hdr.co_num, pck_hdr.pack_num
         from pck_hdr with (readuncommitted)
         where pck_hdr.co_num = @PckhdrCoNum
         and pck_hdr.pack_num between @StartPackNum and @EndPackNum
      end
   end
   close pck_hdrCrs1
   deallocate pck_hdrCrs1
end
else
BEGIN
   IF @CalledFrom = 'InvoiceBuilder'
      insert into @CoList
      select co.co_num, 0
        from co with (readuncommitted)
       INNER JOIN tmp_invoice_builder
          ON co.RowPointer = co_RowPointer AND process_ID = @InvoicBuilderProcessID 
       where charindex(co.type, @InvType) > 0
         and co.cust_num between @StartCustomer and @EndCustomer
         and co.co_num between @StartOrderNum and @EndOrderNum
         and charindex(co.stat, 'OS') > 0
       Group by co.co_num
   ELSE
      insert into @CoList
      select co_num, 0
      from co with (readuncommitted)
      where charindex(co.type, @InvType) > 0
      and co.cust_num between @StartCustomer and @EndCustomer
      and co.co_num between @StartOrderNum and @EndOrderNum
      and charindex(co.stat, 'OS') > 0
END   

IF @CalledFrom = 'InvoiceBuilder'   
   DECLARE co_Crs CURSOR LOCAL STATIC FOR
   SELECT
        co.RowPointer
      , co.cust_num
      , co.cust_seq
      , co.co_num
      , co.end_user_type
      , co.terms_code
      , co.ship_code
      , co.cust_po
      , co.weight
      , co.qty_packages
      , co.disc
      , co.disc_amount
      , co.discount_type
      , round(co.price, currency.places)
      , co.fixed_rate
      , co.exch_rate
      , co.use_exch_rate
      , co.tax_code1
      , co.tax_code2
      , co.frt_tax_code1
      , co.frt_tax_code2
      , co.msc_tax_code1
      , co.msc_tax_code2
      , co.slsman
      , round(co.misc_charges, currency.places)
      , round(co.freight, currency.places)
      , round(co.prepaid_amt, currency.places)
      , round(co.sales_tax, currency.places)
      , round(co.sales_tax_2, currency.places)
      , co.invoiced
      , co.lcr_num
      , co.edi_type
      , co.prepaid_t
      , co.m_charges_t
      , co.freight_t
      , co.sales_tax_t
      , co.sales_tax_t2
      , co.include_tax_in_price
      , co.edi_type
      , co.apply_to_inv_num
      , co.orig_site
      , col.pack_num
      , co.payment_method
   FROM co WITH (UPDLOCK)
      inner join @CoList as col on
         col.co_num = co.co_num
      left outer join custaddr with (readuncommitted) on
         custaddr.cust_num = co.cust_num
         and custaddr.cust_seq = co.cust_seq
      left outer join currency with (readuncommitted) on
         currency.curr_code = custaddr.curr_code
      where exists (select 1 from  tmp_invoice_builder
         where co.RowPointer = co_RowPointer AND process_ID = @InvoicBuilderProcessID)
   ORDER BY co.co_num
ELSE
   DECLARE co_Crs CURSOR LOCAL STATIC FOR
   SELECT
        co.RowPointer
      , co.cust_num
      , co.cust_seq
      , co.co_num
      , co.end_user_type
      , co.terms_code
      , co.ship_code
      , co.cust_po
      , co.weight
      , co.qty_packages
      , co.disc
      , co.disc_amount
      , co.discount_type
      , round(co.price, currency.places)
      , co.fixed_rate
      , co.exch_rate
      , co.use_exch_rate
      , co.tax_code1
      , co.tax_code2
      , co.frt_tax_code1
      , co.frt_tax_code2
      , co.msc_tax_code1
      , co.msc_tax_code2
      , co.slsman
      , round(co.misc_charges, currency.places)
      , round(co.freight, currency.places)
      , round(co.prepaid_amt, currency.places)
      , round(co.sales_tax, currency.places)
      , round(co.sales_tax_2, currency.places)
      , co.invoiced
      , co.lcr_num
      , co.edi_type
      , co.prepaid_t
      , co.m_charges_t
      , co.freight_t
      , co.sales_tax_t
      , co.sales_tax_t2
      , co.include_tax_in_price
      , co.edi_type
      , co.apply_to_inv_num
      , co.orig_site
      , col.pack_num
      , co.payment_method
   FROM co WITH (UPDLOCK)
      inner join @CoList as col on
         col.co_num = co.co_num
      left outer join custaddr with (readuncommitted) on
         custaddr.cust_num = co.cust_num
         and custaddr.cust_seq = co.cust_seq
      left outer join currency with (readuncommitted) on
         currency.curr_code = custaddr.curr_code
   ORDER BY co.co_num
   
OPEN co_Crs
WHILE @Severity = 0
BEGIN /*co_Crs*/
   FETCH co_Crs INTO
        @CoRowPointer
      , @CoCustNum
      , @CoCustSeq
      , @CoCoNum
      , @CoEndUserType
      , @CoTermsCode
      , @CoShipCode
      , @CoCustPo
      , @CoWeight
      , @CoQtyPackages
      , @CoDisc
      , @CoDiscAmount
      , @CoDiscountType
      , @CoPrice
      , @CoFixedRate
      , @CoExchRate
      , @CoUseExchRate
      , @CoTaxCode1
      , @CoTaxCode2
      , @CoFrtTaxCode1
      , @CoFrtTaxCode2
      , @CoMscTaxCode1
      , @CoMscTaxCode2
      , @CoSlsman
      , @CoMiscCharges
      , @CoFreight
      , @CoPrepaidAmt
      , @CoSalesTax
      , @CoSalesTax2
      , @CoInvoiced
      , @CoLcrNum
      , @CoEdiType
      , @CoPrepaidT
      , @CoMChargesT
      , @CoFreightT
      , @CoSalesTaxT
      , @CoSalesTaxT2
      , @CoIncludeTaxInPrice
      , @CoEdiType
      , @CoApplyToInvNum
      , @CoOrigSite
      , @PackNum
      , @PaymentMethod
   IF @@FETCH_STATUS = -1
      BREAK

   SET @UseJPLineMethod = 0
   IF dbo.IsAddonAvailable('SyteLineJP') = 1
   BEGIN
      SELECT
         @ConsumptionTaxHeaderLineMethod = JP_consumption_tax_header_line_method
      FROM customer
      WHERE cust_num = @CoCustNum AND cust_seq = @CoCustSeq

      IF ISNULL(@ConsumptionTaxHeaderLineMethod, NCHAR(1)) = N'L'
         SET @UseJPLineMethod = 1
   END

   SET @CustomerRowPointer     = NULL
   SET @CustomerPayType        = NULL
   SET @CustomerDraftPrintFlag = 0
   SET @CustomerCustBank       = NULL
   SET @CustomerCustNum        = NULL
   SET @CustomerBankCode       = NULL
   SET @CustomerEdiCust        = NULL
   SET @CustomerPrintPackInv   = 0
   SET @CustomerOnePackInv     = 0
   SET @CustomerCustType       = NULL

   SELECT
        @CustomerRowPointer     = RowPointer
      , @CustomerPayType        = pay_type
      , @CustomerDraftPrintFlag = draft_print_flag
      , @CustomerCustBank       = cust_bank
      , @CustomerCustNum        = cust_num
      , @CustomerBankCode       = bank_code
      , @CustomerEdiCust        = edi_cust
      , @CustomerPrintPackInv   = print_pack_inv
      , @CustomerOnePackInv     = one_pack_inv
      , @CustomerCustType       = cust_type
   FROM customer
   WHERE customer.cust_num = @CoCustNum AND
         customer.cust_seq = 0

   IF @CustomerRowPointer IS NULL
   BEGIN
      SET @Infobar = NULL
      EXEC @Severity = dbo.MsgAppSp @Infobar OUTPUT
                          , 'E=NoExist2'
                          , '@customer'
                          , '@customer.cust_num'
                          , @CoCustNum
                          , '@customer.cust_seq'
                          , 0

      GOTO EXIT_SP
   END

   /* IF EDI CUSTOMER, CHECK IF PAPER INVOICE FLAG IS SET */
   SET @CustTpPaperInv = 1
   IF @CustomerEdiCust = 1
   BEGIN      
      SELECT @CustTpPaperInv = paper_inv
      FROM cust_tp
      WHERE cust_num = @CoCustNum AND
            cust_seq = @CoCustSeq 
   END

   IF @CustomerOnePackInv = 1 AND @PackNum = 0 and @InvCred = 'I'
      CONTINUE

   SET @CustaddrRowPointer = NULL
   SET @CustaddrCurrCode   = NULL
   SET @CustaddrState      = NULL
   SET @CustaddrCountry    = NULL

   SELECT
        @CustaddrRowPointer = RowPointer
      , @CustaddrState      = state
      , @CustaddrCurrCode   = curr_code
      , @CustaddrCountry    = country
   FROM custaddr
   WHERE cust_num = @CoCustNum
   AND cust_seq = 0

   IF @CustaddrRowPointer IS NULL
   BEGIN
      SET @Infobar = NULL
      EXEC @Severity = dbo.MsgAppSp @Infobar OUTPUT
                          , 'E=NoExist2'
                          , '@custaddr'
                          , '@custaddr.cust_num'
                          , @CoCustNum
                          , '@custaddr.cust_seq'
                          , 0

      GOTO EXIT_SP
   END

   SET @CusttypeRowPointer   = NULL
   SET @CusttypeTaxablePrice = 0

   IF @CustomerCustType IS NOT NULL
   BEGIN
      SELECT
           @CusttypeRowPointer   = custtype.RowPointer
         , @CusttypeTaxablePrice = custtype.taxable_price
      FROM custtype
      WHERE custtype.cust_type = @CustomerCustType

      IF @CusttypeRowPointer IS NOT NULL AND @CusttypeTaxablePrice IS NULL
      BEGIN
         SET @Infobar = NULL
         EXEC @Severity = dbo.MsgAppSp @Infobar OUTPUT
                          , 'E=NoExist1'
                          , '@custtype'
                          , '@custtype.cust_type'
                          , @CustomerCustType

         GOTO EXIT_SP
      END
   END

   SET @CoDisc = ISNULL(@CoDisc, 0)
   
   /*  Customer Shipment Approvals Flag (1 is approve) */
   SELECT  @CoCustShipmentApprovalRequired = ISNULL ( co.shipment_approval_required , 0 )
   FROM    co co
   WHERE   co.co_num = @CoCoNum
   
   /* PROCESS ONLY IF INVOICING REQUIRED */

   SET @CoitemRowPointer  = NULL
   IF @CalledFrom = 'InvoiceBuilder'
      SELECT TOP 1 /* first */
           @CoitemRowPointer  = coitem.RowPointer
        FROM coitem
       INNER JOIN tmp_invoice_builder
          ON coitem.RowPointer = coitem_RowPointer AND process_ID = @InvoicBuilderProcessID    
       INNER JOIN co_ship ON
            co_ship.co_num = coitem.co_num
         AND co_ship.co_line = coitem.co_line
         AND co_ship.co_release = coitem.co_release
         AND co_ship.do_num IS NULL
         AND ((co_ship.qty_shipped > co_ship.qty_invoiced AND @InvCred = 'I') or
             (co_ship.qty_returned > 0 AND @InvCred = 'C'))
         AND (co_ship.shipment_id IS NULL OR (co_ship.shipment_id IS NOT NULL AND @PaymentMethod = 'C') OR (@InvCred = 'C' AND co_ship.qty_returned  > 0))
         and ((@CustomerOnePackInv = 1 and co_ship.pack_num = @PackNum ) or @CreateFromPackSlip = 0 or
            (@CustomerOnePackInv = 0 and @CreateFromPackSlip = 1
            and (exists (select 1 from @CoListPack as clp where clp.co_num = co_ship.co_num and clp.pack_num = co_ship.pack_num)))
              or (co_ship.pack_num is null
               and exists (select 1 from pckitem where pckitem.co_num = co_ship.co_num and pckitem.co_line = co_ship.co_line
                  and pckitem.co_release = co_ship.co_release
                  and pckitem.pack_num between @StartPackNum and @EndPackNum
                  and ((@CustomerOnePackInv = 1 and pckitem.pack_num = @PackNum ) or @CustomerOnePackInv = 0)))
               )
         AND coitem.invoice_hold = 0
        LEFT OUTER JOIN co_ship_approval_log csal ON 
              co_ship.co_num = csal.co_num AND co_ship.co_line = csal.co_line AND co_ship.co_release = csal.co_release 
              AND co_ship.ship_date = csal.ship_date AND co_ship.date_seq=csal.date_seq
              AND csal.inv_num is null
              AND csal.approval_date BETWEEN IsNull(@StartLastShipDate, csal.approval_date) AND
                                IsNull (dbo.DayEndOf(@EndLastShipDate), csal.approval_date)
       WHERE coitem.co_num = @CoCoNum
         AND (( @InvCred = 'I'
         AND coitem.qty_returned + coitem.qty_shipped > coitem.qty_invoiced)
         OR ( @InvCred = 'C' AND coitem.qty_returned > 0))
         AND CHARINDEX(coitem.stat, 'OF') > 0
         AND coitem.ship_site = @ParmsSite
         AND coitem.co_line BETWEEN IsNull(@StartLine, coitem.co_line) AND
                                    IsNull (@EndLine, coitem.co_line)
         AND coitem.co_release BETWEEN IsNull(@StartRelease, coitem.co_release) AND
                                       IsNull (@EndRelease, coitem.co_release)
         AND ((@CoCustShipmentApprovalRequired = 1 AND @InvCred = 'I' AND csal.co_num IS NOT NULL) OR
             ((@CoCustShipmentApprovalRequired <> 1 OR @InvCred = 'C') AND coitem.ship_date BETWEEN IsNull(@StartLastShipDate, coitem.ship_date)
                                                                             AND IsNull (@ENDLastShipDate, coitem.ship_date))                                                                      )
         AND (( @InvCred = 'I' AND coitem.consolidate = 0)
         OR ( @InvCred = 'C'))
   ELSE
      SELECT TOP 1 /* first */
           @CoitemRowPointer  = coitem.RowPointer
      FROM coitem
         INNER JOIN co_ship ON
            co_ship.co_num = coitem.co_num
            AND co_ship.co_line = coitem.co_line
            AND co_ship.co_release = coitem.co_release
            AND co_ship.do_num IS NULL
            AND ((co_ship.qty_shipped > co_ship.qty_invoiced AND @InvCred = 'I') or
             (co_ship.qty_returned > 0 AND @InvCred = 'C'))
            AND (co_ship.shipment_id IS NULL OR (co_ship.shipment_id IS NOT NULL AND @PaymentMethod = 'C') OR (@InvCred = 'C' AND co_ship.qty_returned  > 0))
            and (@CreateFromPackSlip = 0
               or (@CustomerOnePackInv = 0 and co_ship.pack_num is not null and exists (select 1 from @CoListPack as clp where clp.co_num = co_ship.co_num and clp.pack_num = co_ship.pack_num))
               or (@CustomerOnePackInv = 1 and co_ship.pack_num is not null and co_ship.pack_num = @PackNum and exists (select 1 from @CoList as cl where cl.co_num = co_ship.co_num and cl.pack_num = co_ship.pack_num))
               or (co_ship.pack_num is null
                  and exists (select 1 from @CoList as cl where cl.co_num = co_ship.co_num)
                  and exists (select 1 from pckitem where pckitem.co_num = co_ship.co_num and pckitem.co_line = co_ship.co_line
                  and pckitem.co_release = co_ship.co_release
                  and pckitem.pack_num between @StartPackNum and @EndPackNum
                  and ((@CustomerOnePackInv = 1 and pckitem.pack_num = @PackNum ) or @CustomerOnePackInv = 0))
                  and not exists (select 1 from co_ship as cs1 where cs1.co_num = co_ship.co_num
                     and cs1.co_line = co_ship.co_line
                     and cs1.co_release = co_ship.co_release
                     and cs1.pack_num is not null  )
               )
            )
         LEFT OUTER JOIN co_ship_approval_log csal ON 
              co_ship.co_num = csal.co_num AND co_ship.co_line = csal.co_line AND co_ship.co_release = csal.co_release 
              AND co_ship.ship_date = csal.ship_date AND co_ship.date_seq=csal.date_seq
              AND csal.inv_num is null
              AND csal.approval_date BETWEEN IsNull(@StartLastShipDate, csal.approval_date) AND
                             IsNull (dbo.DayEndOf(@EndLastShipDate), csal.approval_date)
      WHERE coitem.co_num = @CoCoNum
         AND (( @InvCred = 'I'
         AND coitem.qty_returned + coitem.qty_shipped > coitem.qty_invoiced)
         OR ( @InvCred = 'C' AND coitem.qty_returned > 0))
         AND coitem.stat in ('O', 'F')
         AND coitem.ship_site = @ParmsSite
         AND coitem.co_line BETWEEN IsNull(@StartLine, coitem.co_line) AND
                                    IsNull (@EndLine, coitem.co_line)
         AND coitem.co_release BETWEEN IsNull(@StartRelease, coitem.co_release) AND
                                       IsNull (@EndRelease, coitem.co_release)
         AND ((@CoCustShipmentApprovalRequired = 1 AND @InvCred = 'I' AND csal.co_num IS NOT NULL) OR
             ((@CoCustShipmentApprovalRequired <> 1 OR @InvCred = 'C') AND coitem.ship_date BETWEEN IsNull(@StartLastShipDate, coitem.ship_date)
                                                                          AND IsNull (@ENDLastShipDate, coitem.ship_date))                                                                      )
         AND (( @InvCred = 'I' AND coitem.consolidate = 0)
         OR ( @InvCred = 'C'))
         AND coitem.invoice_hold = 0

   IF @CoitemRowPointer IS NULL
      CONTINUE

   IF ISNULL(@PrevCoNum, '') = @CoCoNum
   BEGIN
      SET @CoMChargesT   = ISNULL(@CoMChargesT, 0) + ISNULL(@CoMiscCharges, 0)
      SET @CoFreightT    = ISNULL(@CoFreightT, 0) + ISNULL(@CoFreight, 0)
      SET @CoMiscCharges = 0
      SET @CoFreight     = 0
   END
   ELSE
      SET @PrevCoNum = @CoCoNum

   SET @RecordsFound  = 1
   if @CoOrigSite != @ParmsSite
      set @AllOrdersLocalSite = 0

   SET @CurrLinesDoc  = 0
   SET @LoopLinesDoc  = 0

   IF @CalledFrom = 'InvoiceBuilder'
      SELECT @LoopLinesDoc = COUNT(*)
        FROM coitem
       INNER JOIN tmp_invoice_builder
          ON coitem.RowPointer = coitem_RowPointer AND process_ID = @InvoicBuilderProcessID    
        LEFT OUTER JOIN shipitem ON
         shipitem.co_num = coitem.co_num AND
         shipitem.co_line = coitem.co_line AND
         shipitem.co_release = coitem.co_release AND
         shipitem.batch_id = @BatchId
       LEFT OUTER JOIN  co_ship_approval_log csal on
        csal.co_num = coitem.co_num AND  csal.co_line = coitem.co_line AND  csal.co_release = coitem.co_release
       AND csal.inv_num is null 
       AND csal.approval_date BETWEEN IsNull(@StartLastShipDate, csal.approval_date) AND
                             IsNull (dbo.DayEndOf(@EndLastShipDate), csal.approval_date)
      WHERE coitem.co_num = @CoCoNum
        AND (( @InvCred = 'I' and
               coitem.qty_returned + coitem.qty_shipped > coitem.qty_invoiced)
               or ( @InvCred = 'C' and coitem.qty_returned > 0))
        AND coitem.stat in ('O', 'F')
        AND coitem.ship_site = @ParmsSite
        AND coitem.co_line BETWEEN IsNull(@StartLine, coitem.co_line) AND
                                   IsNull (@EndLine, coitem.co_line)
        AND coitem.co_release BETWEEN IsNull(@StartRelease, coitem.co_release) AND
                                      IsNull (@EndRelease, coitem.co_release)
         AND ((@CoCustShipmentApprovalRequired = 1 AND @InvCred = 'I' AND csal.co_num IS NOT NULL) OR
             ((@CoCustShipmentApprovalRequired <> 1 OR @InvCred = 'C') AND coitem.ship_date BETWEEN IsNull(@StartLastShipDate, coitem.ship_date)
                                                                             AND IsNull (@ENDLastShipDate, coitem.ship_date)))                                   
        AND (( @InvCred = 'I' AND coitem.consolidate = 0)
               OR( @InvCred = 'C'))
        AND (@CheckShipItemActiveFlag = 0 OR shipitem.active = 1)
        AND coitem.invoice_hold = 0
   ELSE
      SELECT @LoopLinesDoc = COUNT(*)
      FROM coitem
      LEFT OUTER JOIN shipitem ON
         shipitem.co_num = coitem.co_num AND
         shipitem.co_line = coitem.co_line AND
         shipitem.co_release = coitem.co_release AND
         shipitem.batch_id = @BatchId
       LEFT OUTER JOIN  co_ship_approval_log csal on
        csal.co_num = coitem.co_num AND  csal.co_line = coitem.co_line AND  csal.co_release = coitem.co_release
       AND csal.inv_num is null 
       AND csal.approval_date BETWEEN IsNull(@StartLastShipDate, csal.approval_date) AND
                             IsNull (dbo.DayEndOf(@EndLastShipDate), csal.approval_date)
      WHERE coitem.co_num = @CoCoNum
        AND (( @InvCred = 'I' and
               coitem.qty_returned + coitem.qty_shipped > coitem.qty_invoiced)
               or ( @InvCred = 'C' and coitem.qty_returned > 0))
        AND coitem.stat in ('O', 'F')
        AND coitem.ship_site = @ParmsSite
        AND coitem.co_line BETWEEN IsNull(@StartLine, coitem.co_line) AND
                                   IsNull (@EndLine, coitem.co_line)
        AND coitem.co_release BETWEEN IsNull(@StartRelease, coitem.co_release) AND
                                      IsNull (@EndRelease, coitem.co_release)
        AND ((@CoCustShipmentApprovalRequired = 1 AND @InvCred = 'I' AND csal.co_num IS NOT NULL) OR
             ((@CoCustShipmentApprovalRequired <> 1 OR @InvCred = 'C') AND coitem.ship_date BETWEEN IsNull(@StartLastShipDate, coitem.ship_date)
                                                                          AND IsNull (@ENDLastShipDate, coitem.ship_date)))                                   
        AND (( @InvCred = 'I' AND coitem.consolidate = 0)
               OR( @InvCred = 'C'))
        AND (@CheckShipItemActiveFlag = 0 OR shipitem.active = 1)
        AND coitem.invoice_hold = 0

   if @LinesSoFar > 0
   and @LinesSoFar + @LoopLinesDoc > 2000
   begin
      set @LinesSoFar = 0
      set @IsPartialCommit = 1
      SET @LocatorVar = 1
      GOTO UPDATE_FILES
      LOCATION_1:
   end
   set @LinesSoFar = @LinesSoFar + @LoopLinesDoc

   WHILE (@LoopLinesDoc > @CurrLinesDoc or @ArparmUsePrePrintedForms = 0)
   BEGIN
      -- This session variable should not be defined at this point.
      EXEC dbo.UnDefineVariableSp 'TmpTaxTablesInUse' , @Infobar
      -- Tmp Tax Table init
      EXEC @Severity = dbo.UseTmpTaxTablesSp @SessionId, @ReleaseTmpTaxTables OUTPUT, @Infobar OUTPUT

      SET @TSubTotal = 0
      SET @TSubtotFull = 0

      /* FIND REQUIRED RECORDS */

      SET @CoWeight      = ISNULL(@CoWeight, 0)
      SET @CoQtyPackages = ISNULL(@CoQtyPackages, 0)
      SET @CoFixedRate   = ISNULL(@CoFixedRate, 0)
      SET @CoExchRate    = ISNULL(@CoExchRate, 0)
      SET @CoUseExchRate = ISNULL(@CoUseExchRate, 0)
      SET @CoMiscCharges = ISNULL(@CoMiscCharges, 0)
      SET @CoFreight     = ISNULL(@CoFreight, 0)
      SET @CoPrepaidAmt  = ISNULL(@CoPrepaidAmt, 0)
      SET @CoPrepaidT    = ISNULL(@CoPrepaidT, 0)
      SET @CoMChargesT   = ISNULL(@CoMChargesT, 0)
      SET @CoFreightT    = ISNULL(@CoFreightT, 0)
      SET @CoSalesTaxT   = ISNULL(@CoSalesTaxT, 0)
      SET @CoSalesTaxT2  = ISNULL(@CoSalesTaxT2, 0)
      SET @CoSalesTax    = ISNULL(@CoSalesTax, 0)
      SET @CoSalesTax2   = ISNULL(@CoSalesTax2, 0)
      SET @CoInvoiced    = ISNULL(@CoInvoiced, 0)
      SET @CoPrice       = ISNULL(@CoPrice, 0)

      SET @CoDisc        = ISNULL(@CoDisc, 0)
      SET @CoDiscAmount  = ISNULL(@CoDiscAmount, 0)

      SET @CoAmount = (@CoPrice - @CoMiscCharges - @CoSalesTax - @CoSalesTax2 -  @CoFreight -
                                  @CoMChargesT - @CoSalesTaxT - @CoSalesTaxT2 -  @CoFreightT)

      /* Workaround schema limitation.  Discount percentage is stored up to 4 decimals, but needs more precision */
      SET @CoDisc = CASE WHEN @CoDiscountType = 'P' THEN @CoDisc
                         ELSE ( (@CoDiscAmount / ( CASE WHEN (@CoDiscAmount + @CoAmount) = 0 THEN 1
                                                        ELSE (@CoDiscAmount + @CoAmount)
                                                   END )
                                ) * 100.00 )
                    END

      SET @CoSalesTax    = 0
      SET @CoSalesTax2   = 0
      SET @TSubTotal = 0
      SET @TSubtotFull = 0
      set @AccumTax1 = 0
      set @AccumTax2 = 0

      SET @CustomerRowPointer     = NULL
      SET @CustomerPayType        = NULL
      SET @CustomerDraftPrintFlag = 0
      SET @CustomerCustBank       = NULL
      SET @CustomerCustNum        = NULL
      SET @CustomerBankCode       = NULL
      SET @CustomerEdiCust        = NULL
      SET @CustomerRevisionDay    = NULL
      set @CustomerUseRevisionPayDays = 0
      SET @CustomerPayDay         = NULL
      SELECT
           @CustomerRowPointer     = customer.RowPointer
         , @CustomerPayType        = customer.pay_type
         , @CustomerDraftPrintFlag = customer.draft_print_flag
         , @CustomerCustBank       = customer.cust_bank
         , @CustomerCustNum        = customer.cust_num
         , @CustomerBankCode       = customer.bank_code
         , @CustomerEdiCust        = customer.edi_cust
         , @CustomerRevisionDay    = customer.revision_day
         , @CustomerUseRevisionPayDays = customer.use_revision_pay_days
         , @CustomerPayDay         = customer.pay_day
      FROM customer
      WHERE customer.cust_num = @CoCustNum
        AND customer.cust_seq = 0

      IF @CustomerRowPointer IS NULL
      BEGIN
         SET @Infobar = NULL
         EXEC @Severity = dbo.MsgAppSp @Infobar OUTPUT, 'E=NoExistForIsAndIs1'
            , '@customer'
            , '@customer.cust_num'
            , @CoCustNum
            , '@customer.cust_seq'
            , @CoCustSeq
            , '@co'
            , '@co.co_num'
            , @CoCoNum

         GOTO EXIT_SP
      END

      IF @InvCred = 'I' AND
         (@pMooreForms <> 'D' AND @CustomerPayType = 'D' AND @CustomerDraftPrintFlag = 1)
          OR
         (@pMooreForms = 'D' AND @pNonDraftCust = 0 AND
          (@CustomerPayType <> 'D'
           OR
          (@CustomerPayType = 'D' AND @CustomerDraftPrintFlag = 0)))
      BEGIN
         BREAK
      END

      SET @CustaddrRowPointer = NULL
      SET @CustaddrState      = NULL
      SET @CustaddrCurrCode   = NULL

      SELECT
           @CustaddrRowPointer = custaddr.RowPointer
         , @CustaddrState      = custaddr.state
         , @CustaddrCurrCode   = custaddr.curr_code
      FROM custaddr
      WHERE custaddr.cust_num =  @CoCustNum
        AND custaddr.cust_seq = @CoCustSeq

      IF (@CustaddrRowPointer IS NULL)
      BEGIN
         SET @Infobar = NULL
         EXEC @Severity = dbo.MsgAppSp @Infobar OUTPUT, 'E=NoExistForIsAndIs1'
            , '@custaddr'
            , '@custaddr.cust_num'
            , @CoCustNum
            , '@customer.cust_seq'
            , @CoCustSeq
            , '@co'
            , '@co.co_num'
            , @CoCoNum

         GOTO EXIT_SP
      END

      SET @TEndAr        = @ArparmsArAcct
      SET @TEndArUnit1   = @ArparmsArAcctUnit1
      SET @TEndArUnit2   = @ArparmsArAcctUnit2
      SET @TEndArUnit3   = @ArparmsArAcctUnit3
      SET @TEndArUnit4   = @ArparmsArAcctUnit4

      SET @CurrencyRowPointer = NULL
      SET @CurrencyCurrCode   = NULL
      SET @CurrencyPlaces     = 2

      SELECT
           @CurrencyRowPointer = currency.RowPointer
         , @CurrencyCurrCode   = currency.curr_code
      , @CurrencyPlaces = currency.places
      , @CurrencyPlacesCp = currency.places_cp
      FROM currency with (readuncommitted)
      WHERE currency.curr_code = @CustaddrCurrCode

      IF @CurrencyRowPointer IS NULL
      BEGIN
         SET @Infobar = NULL
         EXEC @Severity = dbo.MsgAppSp @Infobar OUTPUT
                             , 'E=NoExistForIs2'
                             , '@currency'
                             , '@currency.curr_code'
                             , @CustaddrCurrCode
         , '@customer'
         , '@customer.cust_num'
         , @CoCustNum
         , '@customer.cust_seq'
         , @CoCustSeq

         GOTO EXIT_SP
      END

      SET @EndtypeRowPointer           = NULL
      SET @EndtypeArAcct               = NULL
      SET @EndtypeArAcctUnit1          = NULL
      SET @EndtypeArAcctUnit2          = NULL
      SET @EndtypeArAcctUnit3          = NULL
      SET @EndtypeArAcctUnit4          = NULL
      SET @EndtypeSalesDsAcct          = NULL
      SET @EndtypeSalesDsAcctUnit1     = NULL
      SET @EndtypeSalesDsAcctUnit2     = NULL
      SET @EndtypeSalesDsAcctUnit3     = NULL
      SET @EndtypeSalesDsAcctUnit4     = NULL
      SET @EndtypeSalesAcct            = NULL
      SET @EndtypeSalesAcctUnit1       = NULL
      SET @EndtypeSalesAcctUnit2       = NULL
      SET @EndtypeSalesAcctUnit3       = NULL
      SET @EndtypeSalesAcctUnit4       = NULL
      SET @EndtypeNonInvAcct           = NULL
      SET @EndtypeNonInvAcctUnit1      = NULL
      SET @EndtypeNonInvAcctUnit2      = NULL
      SET @EndtypeNonInvAcctUnit3      = NULL
      SET @EndtypeNonInvAcctUnit4      = NULL
      SET @EndtypeSurchargeAcct        = NULL
      SET @EndtypeSurchargeAcctUnit1   = NULL
      SET @EndtypeSurchargeAcctUnit2   = NULL
      SET @EndtypeSurchargeAcctUnit3   = NULL
      SET @EndtypeSurchargeAcctUnit4   = NULL

      IF @CoEndUserType <> ''
      BEGIN
         SELECT
              @EndtypeRowPointer       = endtype.RowPointer
            , @EndtypeArAcct           = endtype.ar_acct
            , @EndtypeArAcctUnit1      = endtype.ar_acct_unit1
            , @EndtypeArAcctUnit2      = endtype.ar_acct_unit2
            , @EndtypeArAcctUnit3      = endtype.ar_acct_unit3
            , @EndtypeArAcctUnit4      = endtype.ar_acct_unit4
            , @EndtypeSalesDsAcct      = endtype.sales_ds_acct
            , @EndtypeSalesDsAcctUnit1 = endtype.sales_ds_acct_unit1
            , @EndtypeSalesDsAcctUnit2 = endtype.sales_ds_acct_unit2
            , @EndtypeSalesDsAcctUnit3 = endtype.sales_ds_acct_unit3
            , @EndtypeSalesDsAcctUnit4 = endtype.sales_ds_acct_unit4
            , @EndtypeSalesAcct        = endtype.sales_acct
            , @EndtypeSalesAcctUnit1   = endtype.sales_acct_unit1
            , @EndtypeSalesAcctUnit2   = endtype.sales_acct_unit2
            , @EndtypeSalesAcctUnit3   = endtype.sales_acct_unit3
            , @EndtypeSalesAcctUnit4   = endtype.sales_acct_unit4
            , @EndtypeNonInvAcct        = endtype.non_inv_acct
            , @EndtypeNonInvAcctUnit1   = endtype.non_inv_acct_unit1
            , @EndtypeNonInvAcctUnit2   = endtype.non_inv_acct_unit2
            , @EndtypeNonInvAcctUnit3   = endtype.non_inv_acct_unit3
            , @EndtypeNonInvAcctUnit4   = endtype.non_inv_acct_unit4
            , @EndtypeSurchargeAcct      = endtype.surcharge_acct
            , @EndtypeSurchargeAcctUnit1 = endtype.surcharge_acct_unit1
            , @EndtypeSurchargeAcctUnit2 = endtype.surcharge_acct_unit2
            , @EndtypeSurchargeAcctUnit3 = endtype.surcharge_acct_unit3
            , @EndtypeSurchargeAcctUnit4 = endtype.surcharge_acct_unit4

         FROM endtype with (readuncommitted)
         WHERE endtype.end_user_type = @CoEndUserType

         IF @EndtypeRowPointer IS NOT NULL AND @EndtypeArAcct IS NOT NULL
         BEGIN
            SET @TEndAr      = @EndtypeArAcct
            SET @TEndArUnit1 = @EndtypeArAcctUnit1
            SET @TEndArUnit2 = @EndtypeArAcctUnit2
            SET @TEndArUnit3 = @EndtypeArAcctUnit3
            SET @TEndArUnit4 = @EndtypeArAcctUnit4
         END
      END

      IF @CurrparmsCurrCode <> @CurrencyCurrCode
      BEGIN
         SET @TRate = NULL
         EXEC @Severity = dbo.CurrcnvtSp @CurrencyCurrCode, 0, 0, 0, @InvDate, null, null, null, null,
                                         @TRate output, @infobar output, 1, @ResultAmt output
         IF @Severity <> 0
            GOTO EXIT_SP
      END
      ELSE
         SET @TRate = 1

      /* CREATE A/R HEADER */
      EXEC @Severity = dbo.NextInvNumSp
         @Custnum      = @CoCustNum
       , @InvDate      = @InvDate
       , @Type         = @InvCred
       , @InvNum       = @TLastTran OUTPUT
       , @Action       = 'NextNum'
       , @Infobar      = @Infobar OUTPUT

      IF @Severity <> 0
         GOTO EXIT_SP

      IF @TInvNum IS NULL
         SET @TInvNum = '0'

      IF dbo.prefixonly(@TLastTran)<> dbo.prefixonly(@TInvNum)
         SET @TInvNum = @TLastTran

      SET @TInvNum = dbo.MaxInvNum(@TLastTran, @TInvNum)

      EXEC @Severity = dbo.NextInvNumSp
         @Custnum      = @CoCustNum
       , @InvDate      = @InvDate
       , @Type         = @InvCred
       , @InvNum       = @TInvNum OUTPUT
       , @Action       = 'AddedNum'
       , @Infobar      = @Infobar OUTPUT

      set @InvoiceCount = @InvoiceCount + 1

      IF @CustTpPaperInv = 0
         set @EDINoPaperInvoiceCount = @EDINoPaperInvoiceCount   + 1

      IF @Severity <> 0
         GOTO EXIT_SP

      SET @InvHdrRowPointer  = NULL

      SELECT @InvHdrRowPointer  = inv_hdr.RowPointer
      FROM inv_hdr
      WHERE inv_hdr.inv_num = @TInvNum

      IF @InvHdrRowPointer IS NOT NULL
      BEGIN
         SET @Infobar = NULL
         EXEC @Severity = dbo.MsgAppSp @Infobar OUTPUT, 'I=Exist1'
         , '@inv_hdr'
         , '@inv_hdr.inv_num'
         , @TInvNum

         GOTO EXIT_SP
      END
      IF @PackNum is NOT NULL
      BEGIN
         SELECT
         @CoShipCode = ph.ship_code,
         @CoWeight =  ph.weight,
         @CoQtyPackages = ph.qty_packages
         FROM pck_hdr AS ph
         WHERE ph.co_num = @CoCoNum and (pack_num = @PackNum or pack_num in (select pack_num from @CoListPack as clp where clp.co_num = ph.co_num))
      END
      SET @InvHdrRowPointer = NULL
      SET @InvHdrMiscCharges      = 0
      SET @InvHdrFreight          = 0
      SET @InvHdrPrice            = 0
      SET @InvHdrPrepaidAmt       = 0
      SET @InvHdrTotCommDue       = 0
      SET @InvHdrCommCalc         = 0
      SET @InvHdrCommBase         = 0
      SET @InvHdrCommDue          = 0
      SET @InvHdrMiscAcct         = NULL
      SET @InvHdrMiscAcctUnit1    = NULL
      SET @InvHdrMiscAcctUnit2    = NULL
      SET @InvHdrMiscAcctUnit3    = NULL
      SET @InvHdrMiscAcctUnit4    = NULL
      SET @InvHdrFreightAcct      = NULL
      SET @InvHdrFreightAcctUnit1 = NULL
      SET @InvHdrFreightAcctUnit2 = NULL
      SET @InvHdrFreightAcctUnit3 = NULL
      SET @InvHdrFreightAcctUnit4 = NULL
      SET @InvHdrInvNum       = @TInvNum
      SET @InvHdrInvSeq       = 0
      SET @InvHdrCustNum      = @CoCustNum
      SET @InvHdrCustSeq      = @CoCustSeq
      SET @InvHdrCoNum        = @CoCoNum
      SET @InvHdrInvDate      = @InvDate
      SET @InvHdrTermsCode    = @CoTermsCode
      SET @InvHdrShipCode     = @CoShipCode
      SET @InvHdrCustPo       = @CoCustPo
      SET @InvHdrWeight       = @CoWeight
      SET @InvHdrQtyPackages  = @CoQtyPackages
      SET @InvHdrDisc         = @CoDisc
      SET @InvHdrBillType     = 'R'
      SET @InvHdrState        = @CustaddrState
      SET @InvHdrExchRate     = CASE WHEN @CoFixedRate = 1
                                     THEN @CoExchRate
                                     ELSE @TRate
                                     END
      SET @InvHdrUseExchRate  = @CoUseExchRate
      SET @InvHdrTaxCode1     = @CoTaxCode1
      SET @InvHdrTaxCode2     = @CoTaxCode2
      SET @InvHdrFrtTaxCode1  = @CoFrtTaxCode1
      SET @InvHdrFrtTaxCode2  = @CoFrtTaxCode2
      SET @InvHdrMscTaxCode1  = @CoMscTaxCode1
      SET @InvHdrMscTaxCode2  = @CoMscTaxCode2
      SET @InvHdrTaxDate      =
         (CASE WHEN ((@InvHdrInvDate < @TaxparmsLastTaxReport1)
                 AND @TaxparmsLastTaxReport1 IS NOT NULL )
               THEN @TaxparmsLastTaxReport1
               ELSE @InvHdrInvDate
          END)
      /* THE FOLLOWING ARE COMPUTED BELOW */
      SET @InvHdrShipDate  = dbo.Highdate()
      SET @InvHdrSlsman    = @CoSlsman
      SET @InvHdrEcCode    = NULL

      SET @TermsRowPointer = NULL
      SET @TermsDueDays    = 0
      SET @TermsProxCode   = NULL
      SET @TermsProxDay    = 0
      SET @TermsCashOnly   = 0

      SELECT
           @TermsRowPointer   = terms.RowPointer
         , @TermsDueDays      = terms.due_days
         , @TermsProxCode     = terms.prox_code
         , @TermsProxDay      = terms.prox_day
         , @TermsCashOnly     = terms.cash_only
         , @TermsUseMultiDueDates  = terms.use_multi_due_dates
         , @TermsProxMonthToForward     = terms.prox_month_to_forward
         , @TermsProxDiscDay            = terms.prox_disc_day
         , @TermsProxDiscMonthToForward = terms.prox_disc_month_to_forward
         , @TermsCutoffDay              = terms.cutoff_day
         , @TermsHolidayOffsetMethod    = terms.holiday_offset_method
      FROM terms with (readuncommitted)
      WHERE terms.terms_code = @CoTermsCode

      SET @TermsDueDays    = ISNULL(@TermsDueDays, 0)
      SET @TermsProxDay    = ISNULL(@TermsProxDay, 0)

      SET @ArinvRowPointer     = NULL
      SET @ArinvCustNum        = NULL
      SET @ArinvInvNum         = NULL
      SET @ArinvType           = NULL
      SET @ArinvPostFromCo     = 0
      SET @ArinvCoNum          = NULL
      SET @ArinvInvDate        = NULL
      SET @ArinvTaxCode1       = NULL
      SET @ArinvTaxCode2       = NULL
      SET @ArinvTermsCode      = NULL
      SET @ArinvAcct           = NULL
      SET @ArinvAcctUnit1      = NULL
      SET @ArinvAcctUnit2      = NULL
      SET @ArinvAcctUnit3      = NULL
      SET @ArinvAcctUnit4      = NULL
      SET @ArinvRef            = NULL
      SET @ArinvDescription    = NULL
      SET @ArinvExchRate       = 0
      SET @ArinvUseExchRate    = 0
      SET @ArinvFixedRate      = 0
      SET @ArinvPayType        = NULL
      SET @ArinvDraftPrintFlag = NULL
      SET @ArinvDueDate        = NULL
      SET @ArinvInvSeq         = 0
      SET @ArinvSalesTax       = 0
      SET @ArinvSalesTax2      = 0
      SET @ArinvMiscCharges    = 0
      SET @ArinvFreight        = 0
      SET @ArinvAmount         = 0

      IF  @InvCred = 'I'
      BEGIN
         SET @ArtranRowPointer = NULL
         SET @ArtranCustNum    = NULL
         SET @ArtranInvNum     = NULL

         SELECT TOP 1 /* first */
              @ArtranRowPointer = artran.RowPointer
            , @ArtranCustNum    = artran.cust_num
            , @ArtranInvNum     = artran.inv_num
         FROM artran
         WHERE artran.cust_num = @CoCustNum
           AND artran.inv_num = @TInvNum
           AND artran.inv_seq = 0
           AND artran.check_seq = 0

         IF @ArtranRowPointer IS NOT NULL
         BEGIN
            SET @Infobar = NULL
            EXEC @Severity = dbo.MsgAppSp @Infobar OUTPUT, 'I=Exist2'
               , '@artran'
               , '@artran.cust_num'
               , @CoCustNum
               , '@artran.inv_num'
               , @TInvNum

            GOTO EXIT_SP
         END

         SELECT TOP 1 /* first */
            @ArinvRowPointer     = arinv.RowPointer
         FROM arinv
         WHERE arinv.cust_num = @CoCustNum AND arinv.inv_num = @TInvNum

         IF @ArinvRowPointer IS NOT NULL
         BEGIN
            SET @Infobar = NULL
            EXEC @Severity = dbo.MsgAppSp @Infobar OUTPUT, 'I=Exist2'
               , '@arinv'
               , '@arinv.cust_num'
               , @CoCustNum
               , '@arinv.inv_num'
               , @TInvNum

            GOTO EXIT_SP
         END

         SET @ArinvCustNum     = @CoCustNum
         SET @ArinvInvNum      = @TInvNum
         SET @ArinvInvSeq      = 0
         SET @ArinvType        = 'I'
         SET @ArinvPostFromCo  = 1
         SET @ArinvCoNum       = @CoCoNum
         SET @ArinvInvDate     = @InvDate
         SET @ArinvTaxCode1    = @CoTaxCode1
         SET @ArinvTaxCode2    = @CoTaxCode2
         SET @ArinvTermsCode   = @CoTermsCode
         SET @ArinvAcct        = @TEndAr
         SET @ArinvAcctUnit1   = @TEndArUnit1
         SET @ArinvAcctUnit2   = @TEndArUnit2
         SET @ArinvAcctUnit3   = @TEndArUnit3
         SET @ArinvAcctUnit4   = @TEndArUnit4
         SET @ArinvRef         = @TAr + ' ' + @ArinvInvNum
         SET @ArinvDescription = @TInvLabel + ' ' + @ArinvInvNum
         SET @ArinvExchRate    = @InvHdrExchRate
         SET @ArinvUseExchRate = @InvHdrUseExchRate
         SET @ArinvFixedRate   = @CoFixedRate
         SET @ArinvPayType     = @CustomerPayType
         SET @ArinvDraftPrintFlag = (CASE WHEN @CustomerPayType = 'D' AND
                                          @CustomerDraftPrintFlag = 1 AND
                                          @pMooreForms = 'D'
                                          THEN 1
                                          ELSE 0
                                     END)

         IF @TermsUseMultiDueDates = 1 AND @InvCred = 'I'
            SET @ArinvDueDate = NULL
         ELSE
         BEGIN

            IF @CustomerUseRevisionPayDays = 1 and @CustomerRevisionDay IS NOT NULL
            BEGIN
               SELECT @ArInvDateDay = (DATEPART(dw,@ArinvInvDate) + @@datefirst - 1) % 7
               IF @ArInvDateDay <= @CustomerRevisionDay
                  SET @ArinvInvDate = DATEADD(DAY,(cast(@CustomerRevisionDay as int) - @ArInvDateDay), @ArinvInvDate)
               ELSE
                  SET @ArinvInvDate = DATEADD(DAY,(7 - @ArInvDateDay + @CustomerRevisionDay), @ArinvInvDate)
            END

            EXEC @Severity = dbo.DueDateSp @InvoiceDate = @ArinvInvDate
                           , @DueDays    = @TermsDueDays
                           , @ProxCode   = @TermsProxCode
                           , @ProxDay    = @TermsProxDay
                           , @pTermsCode = @CoTermsCode
                           , @ProxMonthToForward     = @TermsProxMonthToForward
                           , @CutoffDay              = @TermsCutoffDay
                           , @HolidayOffsetMethod    = @TermsHolidayOffsetMethod
                           , @ProxDiscMonthToForward = @TermsProxDiscMonthToForward
                           , @DiscDays               = @TermsDiscDays
                           , @ProxDiscDay            = @TermsProxDiscDay
                           , @DueDate    = @ArinvDueDate   OUTPUT
                           , @DiscDate    = @ArinvDiscDate   OUTPUT

            IF @CustomerUseRevisionPayDays = 1 and @CustomerRevisionDay IS NOT NULL
            BEGIN
               SELECT @ArInvDueDateDay = (DATEPART(dw,@ArinvDueDate) + @@datefirst - 1) % 7
               IF @ArInvDueDateDay <= @CustomerPayDay
                  SET @ArinvDueDate = DATEADD(DAY,(@CustomerPayDay - @ArInvDueDateDay), @ArinvDueDate)
               ELSE
                  SET @ArinvDueDate = DATEADD(DAY,(7 - @ArInvDueDateDay + @CustomerPayDay), @ArinvDueDate)
            END
         END

         IF @Severity <> 0
            GOTO EXIT_SP

      END /* IF  @InvCred = 'I' */
      ELSE
      BEGIN /* INPUT @InvCred = 'C' */

         SELECT TOP 1 /* last */
              @ArinvRowPointer     = arinv.RowPointer
            , @ArinvCustNum        = arinv.cust_num
            , @ArinvInvNum         = arinv.inv_num
            , @ArinvType           = arinv.type
            , @ArinvPostFromCo     = arinv.post_from_co
            , @ArinvCoNum          = arinv.co_num
            , @ArinvInvDate        = arinv.inv_date
            , @ArinvTaxCode1       = arinv.tax_code1
            , @ArinvTaxCode2       = arinv.tax_code2
            , @ArinvTermsCode      = arinv.terms_code
            , @ArinvAcct           = arinv.acct
            , @ArinvAcctUnit1      = arinv.acct_unit1
            , @ArinvAcctUnit2      = arinv.acct_unit2
            , @ArinvAcctUnit3      = arinv.acct_unit3
            , @ArinvAcctUnit4      = arinv.acct_unit4
            , @ArinvRef            = arinv.ref
            , @ArinvDescription    = arinv.description
            , @ArinvExchRate       = arinv.exch_rate
            , @ArinvUseExchRate    = arinv.use_exch_rate
            , @ArinvFixedRate      = arinv.fixed_rate
            , @ArinvPayType        = arinv.pay_type
            , @ArinvDraftPrintFlag = arinv.draft_print_flag
            , @ArinvDueDate        = arinv.due_date
            , @ArinvInvSeq         = arinv.inv_seq
            , @ArinvSalesTax       = arinv.sales_tax
            , @ArinvSalesTax2      = arinv.sales_tax_2
            , @ArinvMiscCharges    = arinv.misc_charges
            , @ArinvFreight        = arinv.freight
            , @ArinvAmount         = arinv.amount
         FROM arinv
         WHERE arinv.cust_num = @CoCustNum
           AND arinv.inv_num = '0'
         ORDER BY arinv.inv_seq DESC

         -- ArinvInvSeq is set by the trigger
         SET @ArinvExchRate       = ISNULL(@ArinvExchRate,0)
         SET @ArinvUseExchRate    = ISNULL(@ArinvUseExchRate,0)
         SET @ArinvFixedRate      = ISNULL(@ArinvFixedRate,0)
         SET @ArinvSalesTax       = ISNULL(@ArinvSalesTax,0)
         SET @ArinvSalesTax2      = ISNULL(@ArinvSalesTax2,0)
         SET @ArinvMiscCharges    = ISNULL(@ArinvMiscCharges,0)
         SET @ArinvFreight        = ISNULL(@ArinvFreight,0)
         SET @ArinvAmount         = ISNULL(@ArinvAmount,0)

         SET @ArinvCustNum    = @CoCustNum
         SET @ArinvInvNum     = @TInvNum
         SET @ArinvType       = 'C'
         SET @ArinvCoNum      = @CoCoNum
         SET @ArinvInvDate    = @InvDate
         SET @ArinvDueDate    = @InvDate
         SET @ArinvTaxCode1   = @CoTaxCode1
         SET @ArinvTaxCode2   = @CoTaxCode2
         SET @ArinvTermsCode  = @CoTermsCode
         SET @ArinvAcct       = @TEndAr
         SET @ArinvAcctUnit1  = @TEndArUnit1
         SET @ArinvAcctUnit2  = @TEndArUnit2
         SET @ArinvAcctUnit3  = @TEndArUnit3
         SET @ArinvAcctUnit4  = @TEndArUnit4
         /* amount, misc-charges, sales-tax, freight SET BELOW */
         SET @ArinvRef         = @TArCredit
         SET @ArinvDescription = @TOpen + ' ' + @TInvNum
         SET @ArinvPostFromCo  = 1
         SET @ArinvExchRate    = @InvHdrExchRate
         SET @ArinvUseExchRate = @InvHdrUseExchRate
         SET @ArinvFixedRate   = @CoFixedRate
         SET @ArinvPayType     = @CustomerPayType
         SET @ArinvDraftPrintFlag = 0
         SET @ArinvInvSeq = ISNULL(@ArinvInvSeq, 0)
      END /* INPUT @InvCred = 'C' */

      IF @ArinvDueDate IS NULL AND (@TermsUseMultiDueDates <> 1 OR @InvCred <> 'I')
         SET @ArinvDueDate = @ArinvInvDate

      SET @ArinvRowPointer = Newid()

      IF @CustomerUseRevisionPayDays = 1 and @CustomerRevisionDay IS NOT NULL AND @ArinvType = 'I'
         SET @ArinvApprovalStatus  = 'P'
      ELSE
         SET @ArinvApprovalStatus  = NULL

      INSERT INTO @TmpArinv (
           cust_num
         , inv_num
         , inv_seq
         , type
         , post_from_co
         , co_num
         , inv_date
         , tax_code1
         , tax_code2
         , terms_code
         , acct
         , acct_unit1
         , acct_unit2
         , acct_unit3
         , acct_unit4
         , ref
         , description
         , exch_rate
         , use_exch_rate
         , fixed_rate
         , pay_type
         , draft_print_flag
         , due_date
         , sales_tax
         , sales_tax_2
         , misc_charges
         , freight
         , amount
         , RowPointer
         , approval_status
         , include_tax_in_price
         , apply_to_inv_num
         , terms_use_multiDueDates
         )
      VALUES(
           @ArinvCustNum
         , @ArinvInvNum
         , @ArinvInvSeq
         , @ArinvType
         , @ArinvPostFromCo
         , @ArinvCoNum
         , @ArinvInvDate
         , @ArinvTaxCode1
         , @ArinvTaxCode2
         , @ArinvTermsCode
         , @ArinvAcct
         , @ArinvAcctUnit1
         , @ArinvAcctUnit2
         , @ArinvAcctUnit3
         , @ArinvAcctUnit4
         , @ArinvRef
         , @ArinvDescription
         , @ArinvExchRate
         , @ArinvUseExchRate
         , @ArinvFixedRate
         , @ArinvPayType
         , @ArinvDraftPrintFlag
         , @ArinvDueDate
         , @ArinvSalesTax
         , @ArinvSalesTax2
         , @ArinvMiscCharges
         , @ArinvFreight
         , @ArinvAmount
         , @ArinvRowPointer
         , @ArinvApprovalStatus
         , 0
         , (CASE WHEN @ArInvType = 'I'
                 THEN @ArinvInvNum
                 ELSE ISNULL(@CoApplyToInvNum,'0')
            END)
         , @TermsUseMultiDueDates
         )

      SET @InvHdrRowPointer = NewId()
      INSERT INTO #TmpInvHdr(
           inv_num
         , inv_seq
         , cust_num
         , cust_seq
         , co_num
         , inv_date
         , terms_code
         , ship_code
         , cust_po
         , weight
         , qty_packages
         , disc
         , bill_type
         , state
         , exch_rate
         , use_exch_rate
         , tax_code1
         , tax_code2
         , frt_tax_code1
         , frt_tax_code2
         , msc_tax_code1
         , msc_tax_code2
         , tax_Date
         , ship_date
         , slsman
         , ec_code
         , misc_charges
         , freight
         , price
         , prepaid_amt
         , tot_comm_due
         , comm_calc
         , comm_base
         , comm_due
         , misc_acct
         , misc_acct_unit1
         , misc_acct_unit2
         , misc_acct_unit3
         , misc_acct_unit4
         , freight_acct
         , freight_acct_unit1
         , freight_acct_unit2
         , freight_acct_unit3
         , freight_acct_unit4
         , RowPointer
         , curr_code
         , curr_places
         , edi_cust
         , cust_tp_paper_invoice
         )
      VALUES(
           @InvHdrInvNum
         , @InvHdrInvSeq
         , @InvHdrCustNum
         , @InvHdrCustSeq
         , @InvHdrCoNum
         , @InvHdrInvDate
         , @InvHdrTermsCode
         , @InvHdrShipCode
         , @InvHdrCustPo
         , @InvHdrWeight
         , @InvHdrQtyPackages
         , @InvHdrDisc
         , @InvHdrBillType
         , @InvHdrState
         , @InvHdrExchRate
         , @InvHdrUseExchRate
         , @InvHdrTaxCode1
         , @InvHdrTaxCode2
         , @InvHdrFrtTaxCode1
         , @InvHdrFrtTaxCode2
         , @InvHdrMscTaxCode1
         , @InvHdrMscTaxCode2
         , @InvHdrTaxDate
         , @InvHdrShipDate
         , @InvHdrSlsman
         , @InvHdrEcCode
         , NULL
         , NULL
         , NULL
         , NULL
         , NULL
         , NULL
         , NULL
         , NULL
         , NULL
         , NULL
         , NULL
         , NULL
         , NULL
         , NULL
         , NULL
         , NULL
         , NULL
         , NULL
         , @InvHdrRowpointer
         , @CurrencyCurrCode
         , @CurrencyPlaces
         , @CustomerEdiCust
         , @CustTpPaperInv 
         )

      IF @StartInvNum = '0' or @InvHdrInvNum < @StartInvNum
         SET @StartInvNum = @InvHdrInvNum
   
      IF @EndInvNum = '0' or @InvHdrInvNum > @EndInvNum
         SET @EndInvNum = @InvHdrInvNum

      /* PROCESSES ALL LINE ITEMS ON THIS ORDER */
      /* coitem loop processing, inv-item, inv-stax */

      SET @TDistSeq = 0
      SET @RowNum           = 0
      SET @BalAdj           = 0
      SET @DAmt             = 0

      SET @AmountToApply    = 0
      SET @AmountToApply2   = 0
      SET @AmountApplied    = 0
      SET @BilledFor        = 0
      SET @BilledFor2       = 0
      SET @DPrice           = 0
      SET @I                = 0
      SET @LeftToApply      = 0
      SET @OLvlDiscLineNet  = 0
      SET @PartiallyApplied = 0
      SET @QtyToInvoice     = 0
      SET @Severity         = 0
      SET @TProgBill        = 0
      SET @TApp             = 0
      SET @TCreditMemoCost  = 0
      SET @TReturned        = 0
      SET @TQtyRemain       = 0
      SET @TLineNet         = 0
      SET @TLineTot         = 0
      SET @TProgAcct        = NULL
      SET @TProgAcctUnit1   = NULL
      SET @TProgAcctUnit2   = NULL
      SET @TProgAcctUnit3   = NULL
      SET @TProgAcctUnit4   = NULL
      SET @TMatlCost        = 0
      SET @TMatlShip        = 0
      SET @TMatltype        = NULL
      SET @TStat            = NULL
      SET @TShipDate        = NULL
      SET @TCoitemQty       = 0
      SET @TBalAdj          = 0
      SET @TXInvProAmount   = 0
      SET @TInvAmount       = 0
      SET @TTaxablePrice    = NULL

      SET @InvHdrExchRate   = ISNULL(@InvHdrExchRate, 0)
      SET @InvHdrCost       = 0

      SET @TMatltype = CASE WHEN  @InvCred = 'I' then 'I' else 'W' END
      SET @TStat = CASE WHEN  @InvCred = 'I' then 'O' else 'I' END
      
      IF @CalledFrom = 'InvoiceBuilder'
         DECLARE coitem_Crs CURSOR LOCAL STATIC FOR
         SELECT
              coitem.RowPointer
            , coitem.item
            , coitem.co_num
            , coitem.co_line
            , coitem.co_release
            , coitem.ship_date
            , (CASE WHEN @CoCustShipmentApprovalRequired = 1 AND @InvCred = 'I'
               THEN (SELECT SUM(ISNULL(qty_approved , 0)) from co_ship_approval_log WHERE
                          co_num = coitem.co_num AND
                          co_line = coitem.co_line  AND
                          co_release = coitem.co_release AND 
                          inv_num is null AND 
                          approval_date BETWEEN IsNull(@StartLastShipDate, approval_date) AND
                                               IsNull (dbo.DayEndOf(@EndLastShipDate), approval_date))
               ELSE coitem.qty_shipped
               END) qty_shipped
            , coitem.qty_invoiced
            , coitem.price
            , coitem.price_conv
            , coitem.disc
            , coitem.qty_ordered
            , coitem.prg_bill_tot
            , coitem.prg_bill_app
            , coitem.process_ind
            , coitem.cons_num
            , coitem.tax_code1
            , coitem.tax_code2
            , coitem.cust_po
            , coitem.qty_returned
            , coitem.cost
            , coitem.cgs_total
            , coitem.whse
            , coitem.ref_type
            , coitem.ref_num
            , coitem.ref_line_suf
            , coitem.non_inv_acct
            , coitem.non_inv_acct_unit1
            , coitem.non_inv_acct_unit2
            , coitem.non_inv_acct_unit3
            , coitem.non_inv_acct_unit4
            , coitem.u_m
         FROM coitem
        INNER JOIN tmp_invoice_builder
           ON coitem.RowPointer = coitem_RowPointer AND process_ID = @InvoicBuilderProcessID    
         LEFT OUTER JOIN shipitem ON
            shipitem.co_num = coitem.co_num AND
            shipitem.co_line = coitem.co_line AND
            shipitem.co_release = coitem.co_release AND
            shipitem.batch_id = @BatchId           
         WHERE coitem.co_num = @CoCoNum
           AND (( @InvCred = 'I' AND
                  coitem.qty_returned + coitem.qty_shipped > coitem.qty_invoiced)
                  OR ( @InvCred = 'C' AND coitem.qty_returned > 0))
           AND coitem.stat in ('O', 'F')
           AND coitem.ship_site = @ParmsSite
           AND coitem.co_line BETWEEN IsNull(@StartLine, coitem.co_line) AND IsNull (@EndLine, coitem.co_line)
           AND coitem.co_release BETWEEN IsNull(@StartRelease, coitem.co_release) AND IsNull (@EndRelease, coitem.co_release)
           AND ((@CoCustShipmentApprovalRequired = 1 AND @InvCred = 'I') OR
               (@CoCustShipmentApprovalRequired <> 1 OR @InvCred = 'C') AND coitem.ship_date BETWEEN IsNull(@StartLastShipDate, coitem.ship_date)
                                                                             AND IsNull (@ENDLastShipDate, coitem.ship_date)) 
           AND (( @InvCred = 'I' AND coitem.consolidate = 0)
                  OR( @InvCred = 'C'))
           AND (@CheckShipItemActiveFlag = 0 OR shipitem.active = 1)
           AND coitem.invoice_hold = 0
      ELSE

         DECLARE coitem_Crs CURSOR LOCAL STATIC FOR
         SELECT
              coitem.RowPointer
            , coitem.item
            , coitem.co_num
            , coitem.co_line
            , coitem.co_release
            , coitem.ship_date
            , (CASE WHEN @CoCustShipmentApprovalRequired = 1 AND @InvCred = 'I'
               THEN (SELECT SUM(ISNULL(qty_approved , 0)) from co_ship_approval_log WHERE
                          co_num = coitem.co_num AND
                          co_line = coitem.co_line  AND
                          co_release = coitem.co_release AND 
                          inv_num is null AND 
                          approval_date BETWEEN IsNull(@StartLastShipDate, approval_date) AND
                                               IsNull (dbo.DayEndOf(@EndLastShipDate), approval_date))
               ELSE coitem.qty_shipped
               END) qty_shipped
            , coitem.qty_invoiced
            , coitem.price
            , coitem.price_conv
            , coitem.disc
            , coitem.qty_ordered
            , coitem.prg_bill_tot
            , coitem.prg_bill_app
            , coitem.process_ind
            , coitem.cons_num
            , coitem.tax_code1
            , coitem.tax_code2
            , coitem.cust_po
            , coitem.qty_returned
            , coitem.cost
            , coitem.cgs_total
            , coitem.whse
            , coitem.ref_type
            , coitem.ref_num
            , coitem.ref_line_suf
            , coitem.non_inv_acct
            , coitem.non_inv_acct_unit1
            , coitem.non_inv_acct_unit2
            , coitem.non_inv_acct_unit3
            , coitem.non_inv_acct_unit4
            , coitem.u_m
         FROM coitem
         LEFT OUTER JOIN shipitem ON
            shipitem.co_num = coitem.co_num AND
            shipitem.co_line = coitem.co_line AND
            shipitem.co_release = coitem.co_release AND
            shipitem.batch_id = @BatchId           
         WHERE coitem.co_num = @CoCoNum
           AND (( @InvCred = 'I' AND
                  coitem.qty_returned + coitem.qty_shipped > coitem.qty_invoiced)
                  OR ( @InvCred = 'C' AND coitem.qty_returned > 0))
           AND coitem.stat in ('O', 'F')
           AND coitem.ship_site = @ParmsSite
           AND coitem.co_line BETWEEN IsNull(@StartLine, coitem.co_line) AND IsNull (@EndLine, coitem.co_line)
           AND coitem.co_release BETWEEN IsNull(@StartRelease, coitem.co_release) AND IsNull (@EndRelease, coitem.co_release)
           AND ((@CoCustShipmentApprovalRequired = 1 AND @InvCred = 'I') OR
               (@CoCustShipmentApprovalRequired <> 1 OR @InvCred = 'C') AND coitem.ship_date BETWEEN IsNull(@StartLastShipDate, coitem.ship_date)
                                                                          AND IsNull (@ENDLastShipDate, coitem.ship_date)) 
           AND (( @InvCred = 'I' AND coitem.consolidate = 0)
                  OR( @InvCred = 'C'))
           AND (@CheckShipItemActiveFlag = 0 OR shipitem.active = 1)
           AND coitem.invoice_hold = 0

      OPEN coitem_Crs
      WHILE @Severity = 0
      BEGIN
         FETCH coitem_Crs INTO
              @CoitemRowPointer
            , @CoitemItem
            , @CoitemCoNum
            , @CoitemCoLine
            , @CoitemCoRelease
            , @CoitemShipDate
            , @CoitemQtyShipped
            , @CoitemQtyInvoiced
            , @CoitemPrice
            , @CoitemPriceConv
            , @CoitemDisc
            , @CoitemQtyOrdered
            , @CoitemPrgBillTot
            , @CoitemPrgBillApp
            , @CoitemProcessInd
            , @CoitemConsNum
            , @CoitemTaxCode1
            , @CoitemTaxCode2
            , @CoitemCustPo
            , @CoitemQtyReturned
            , @CoitemCost
            , @CoitemCgsTotal
            , @CoitemWhse
            , @CoitemRefType
            , @CoitemRefNum
            , @CoitemRefLineSuf
            , @CoItemNonInvAcct
            , @CoitemNonInvAcctUnit1 
            , @CoitemNonInvAcctUnit2
            , @CoitemNonInvAcctUnit3
            , @CoitemNonInvAcctUnit4
            , @CoitemUM
         IF @@FETCH_STATUS = -1
             BREAK

         SET @RowNum = @RowNum +1

         SET @CoitemQtyShipped = ISNULL(@CoitemQtyShipped, 0)
         SET @CoitemQtyInvoiced = ISNULL(@CoitemQtyInvoiced, 0)
         SET @CoitemPrice = ISNULL(@CoitemPrice, 0)
         SET @CoitemDisc = ISNULL(@CoitemDisc, 0)
         SET @CoitemQtyOrdered = ISNULL(@CoitemQtyOrdered, 0)
         SET @CoitemPrgBillTot = ISNULL(@CoitemPrgBillTot, 0)
         SET @CoitemPrgBillApp = ISNULL(@CoitemPrgBillApp, 0)
         SET @CoitemQtyReturned = ISNULL(@CoitemQtyReturned, 0)
         SET @CoitemCost = ISNULL(@CoitemCost, 0)
         SET @CoitemCgsTotal = ISNULL(@CoitemCgsTotal, 0)

         if exists (select 1 from @TmpCoitem where RowPointer = @CoitemRowPointer)
            select @CoitemPrgBillApp = prg_bill_app
            , @CoitemQtyInvoiced = qty_invoiced
            , @CoitemQtyReturned = qty_returned
            from @TmpCoitem
            where RowPointer = @CoitemRowPointer

         -- Init Invoice Item History
         SET @InvItemInvNum      = NULL
         SET @InvItemInvSeq      = 0
         SET @InvItemInvLine     = 0
         SET @InvItemCoNum       = NULL
         SET @InvItemCoLine      = 0
         SET @InvItemCoRelease   = 0
         SET @InvItemItem        = NULL
         SET @InvItemDisc        = 0
         SET @InvItemPrice       = 0
         SET @InvItemProcessInd  = @CoitemProcessInd
         SET @InvItemConsNum     = NULL
         SET @InvItemTaxCode1    = NULL
         SET @InvItemTaxCode2    = NULL
         SET @InvItemCustPo      = NULL
         SET @InvItemTaxDate     = NULL
         SET @InvItemQtyInvoiced = 0
         SET @InvItemCost        = 0
         SET @InvItemSalesAcct   = NULL
         SET @InvItemSalesAcctUnit1 = NULL
         SET @InvItemSalesAcctUnit2 = NULL
         SET @InvItemSalesAcctUnit3 = NULL
         SET @InvItemSalesAcctUnit4 = NULL
         SET @InvItemExciseTaxPercent = 0
         
         SET @NonInventoryItem = 0

         SET @CoShipRowPointer  = NULL
         SELECT TOP 1 /* first */
              @CoShipRowPointer  = co_ship.RowPointer
         FROM co_ship
         LEFT OUTER JOIN co_ship_approval_log csal ON 
          co_ship.co_num = csal.co_num AND co_ship.co_line = csal.co_line 
          AND co_ship.co_release = csal.co_release AND co_ship.ship_date = csal.ship_date 
          AND co_ship.date_seq=csal.date_seq AND csal.inv_num is null  
          AND csal.approval_date BETWEEN IsNull(@StartLastShipDate, csal.approval_date) AND
                             IsNull (dbo.DayEndOf(@EndLastShipDate), csal.approval_date) 
         WHERE co_ship.co_num = @CoitemCoNum
           AND co_ship.co_line = @CoitemCoLine
           AND co_ship.co_release = @CoitemCoRelease
           AND ((@CoCustShipmentApprovalRequired = 1 AND @InvCred = 'I' AND csal.co_num IS NOT NULL) OR 
               ((@CoCustShipmentApprovalRequired <> 1 OR @InvCred = 'C') AND (co_ship.qty_shipped + co_ship.qty_returned - co_ship.qty_invoiced) > 0))
           AND (co_ship.do_num = '' OR co_ship.do_num IS NULL)
           AND (co_ship.shipment_id IS NULL OR (co_ship.shipment_id IS NOT NULL AND @PaymentMethod = 'C') OR (@InvCred = 'C' AND co_ship.qty_returned  > 0))
         and (@CreateFromPackSlip = 0
            or (@CustomerOnePackInv = 0 and co_ship.pack_num is not null and exists (select 1 from @CoListPack as clp where clp.co_num = co_ship.co_num and clp.pack_num = co_ship.pack_num))
            or (@CustomerOnePackInv = 1 and co_ship.pack_num is not null and co_ship.pack_num = @PackNum and exists (select 1 from @CoList as cl where cl.co_num = co_ship.co_num and cl.pack_num = co_ship.pack_num))
            or (co_ship.pack_num is null
               and exists (select 1 from @CoList as cl where cl.co_num = co_ship.co_num )
               and exists (select 1 from pckitem where pckitem.co_num = co_ship.co_num and pckitem.co_line = co_ship.co_line
                  and pckitem.co_release = co_ship.co_release
                  and pckitem.pack_num between @StartPackNum and @EndPackNum
                  and ((@CustomerOnePackInv = 1 and pckitem.pack_num = @PackNum ) or @CustomerOnePackInv = 0))
               and not exists (select 1 from co_ship as cs1 where cs1.co_num = co_ship.co_num
                  and cs1.co_line = co_ship.co_line
                  and cs1.co_release = co_ship.co_release
                  and cs1.pack_num is not null)
            )
         )

         IF @CoShipRowPointer IS NULL AND @InvCred = 'I'
            CONTINUE

         SET @TCoitemQty = @CoitemQtyOrdered - @CoitemQtyInvoiced + @CoitemQtyReturned
         SET @TCoitemQty = CASE WHEN @TCoitemQty > 0 THEN @TCoitemQty ELSE 0 END
         SET @TBalAdj = 
                  (CASE WHEN @CoParmsUseAltPriceCalc = 1 THEN
                         round( (round(@CoitemPrice * (1 - @CoitemDisc / 100), @CurrencyPlaces) * @TCoitemQty), @CurrencyPlaces)
                         - (@CoitemPrgBillTot - @CoitemPrgBillApp)
                   ELSE
                         round(@TCoitemQty * @CoitemPrice * (1 - @CoitemDisc / 100), @CurrencyPlaces)
                        - (@CoitemPrgBillTot - @CoitemPrgBillApp)
                   END)

         SET @BalAdj = @BalAdj - @TBalAdj
         SET @TCoItemPrice = @TCoItemPrice + 
                             (CASE WHEN @CoParmsUseAltPriceCalc = 1 THEN
                                 round( (round(@CoitemPrice * (1 - @CoitemDisc / 100), @CurrencyPlaces) * @CoitemQtyOrdered), @CurrencyPlaces)
                              ELSE
                                 round(@CoitemQtyOrdered * @CoitemPrice * (1 - @CoitemDisc / 100), @CurrencyPlaces)
                              END)

         SET @ItemRowPointer    = NULL
         SET @ItemSerialTracked = 0
         SET @ItemItem          = NULL
         SET @ItemUWsPrice      = 0
         SET @ItemProductCode   = NULL
         SET @ItemSubjectToExciseTax = 0
         SET @ItemExciseTaxPercent = 0

         SELECT
              @ItemRowPointer         = item.RowPointer
            , @ItemSerialTracked      = item.serial_tracked
            , @ItemItem               = item.item
            , @ItemUWsPrice           = item.u_ws_price
            , @ItemProductCode        = item.product_code
            , @ItemSubjectToExciseTax = item.subject_to_excise_tax
            , @ItemExciseTaxPercent   = item.excise_tax_percent 
         FROM item
         WHERE item.item=@CoitemItem

         SET @ItemUWsPrice    = ISNULL(@ItemUWsPrice, 0)

         IF @ItemRowPointer IS NULL
         BEGIN
            SET @NonInventoryItem = 1
         END

         IF @ItemSubjectToExciseTax <> 1
            SET @ItemExciseTaxPercent = 0

         SET @TMatlCost = 0
         SET @QtyToInvoice = 0

         IF  @InvCred = 'I'  /* Invoice */
         BEGIN
            DECLARE co_ship_Crs CURSOR LOCAL STATIC FOR
            SELECT
                 co_ship.RowPointer
               , (CASE WHEN @CoCustShipmentApprovalRequired = 1 AND @InvCred = 'I'
                     THEN (SELECT SUM(ISNULL(qty_approved , 0)) from co_ship_approval_log WHERE
                       co_num = co_ship.co_num AND co_line = co_ship.co_line  
                       AND co_release = co_ship.co_release AND  ship_date = co_ship.ship_date 
                       AND date_seq=co_ship.date_seq AND inv_num is null 
                       AND approval_date BETWEEN IsNull(@StartLastShipDate, approval_date) AND
                                            IsNull (dbo.DayEndOf(@EndLastShipDate), approval_date))
                    ELSE co_ship.qty_shipped
                    END) qty_shipped
               , co_ship.qty_returned
               , co_ship.cost
               , co_ship.pack_num
            FROM co_ship            
               LEFT OUTER JOIN co_ship_approval_log csal ON 
                co_ship.co_num = csal.co_num AND co_ship.co_line = csal.co_line AND 
                co_ship.co_release = csal.co_release AND co_ship.ship_date = csal.ship_date AND 
                co_ship.date_seq=csal.date_seq AND csal.inv_num is null  AND 
                csal.approval_date BETWEEN IsNull(@StartLastShipDate, csal.approval_date) AND
                                   IsNull (dbo.DayEndOf(@EndLastShipDate), csal.approval_date)                   
            WHERE co_ship.co_num=@CoitemCoNum
              AND co_ship.co_line = @CoitemCoLine
              AND co_ship.co_release = @CoitemCoRelease
              AND ((@CoCustShipmentApprovalRequired = 1 AND @InvCred = 'I' AND csal.co_num IS NOT NULL) OR 
                  ((@CoCustShipmentApprovalRequired <> 1 OR @InvCred = 'C') AND (co_ship.qty_shipped + co_ship.qty_returned - co_ship.qty_invoiced) > 0))              
              AND (co_ship.do_num = '' OR co_ship.do_num IS NULL)
              AND (co_ship.shipment_id IS NULL OR (co_ship.shipment_id IS NOT NULL AND @PaymentMethod = 'C'))
            and (@CreateFromPackSlip = 0
               or (@CustomerOnePackInv = 0 and co_ship.pack_num is not null and exists (select 1 from @CoListPack as clp where clp.co_num = co_ship.co_num and clp.pack_num = co_ship.pack_num))
               or (@CustomerOnePackInv = 1 and co_ship.pack_num is not null and co_ship.pack_num = @PackNum and exists (select 1 from @CoList as cl where cl.co_num = co_ship.co_num and cl.pack_num = co_ship.pack_num))
               or (co_ship.pack_num is null
                  and exists (select 1 from @CoList as cl where cl.co_num = co_ship.co_num )
                  and exists (select 1 from pckitem where pckitem.co_num = co_ship.co_num and pckitem.co_line = co_ship.co_line
                     and pckitem.co_release = co_ship.co_release
                     and pckitem.pack_num between @StartPackNum and @EndPackNum
                     and ((@CustomerOnePackInv = 1 and pckitem.pack_num = @PackNum ) or @CustomerOnePackInv = 0))
                  and not exists (select 1 from co_ship as cs1 where cs1.co_num = co_ship.co_num
                     and cs1.co_line = co_ship.co_line
                     and cs1.co_release = co_ship.co_release
                     and cs1.pack_num is not null)
               )
            )
            GROUP BY co_ship.co_num,co_ship.co_line,co_ship.co_release,co_ship.ship_date,co_ship.RowPointer
                     ,co_ship.date_seq, co_ship.qty_returned, co_ship.cost, co_ship.pack_num,co_ship.qty_shipped
            
            
            OPEN co_ship_Crs
            WHILE @Severity = 0
            BEGIN
               FETCH co_ship_Crs INTO
                    @CoShipRowPointer
                  , @CoShipQtyShipped
                  , @CoShipQtyReturned
                  , @CoShipCost
                  , @CoShipPackNum
               IF @@FETCH_STATUS = -1
                  BREAK

               SET @CoShipQtyShipped  = ISNULL(@CoShipQtyShipped, 0)
               SET @CoShipQtyReturned = ISNULL(@CoShipQtyReturned, 0)
               SET @CoShipCost        = ISNULL(@CoShipCost, 0)

               SET @TMatlCost = @TMatlCost + (@CoShipCost * @CoShipQtyShipped)
               SET @CoShipQtyInvoiced = @CoShipQtyShipped + @CoShipQtyReturned
               SET @QtyToInvoice = @QtyToInvoice + @CoShipQtyInvoiced

               IF NOT EXISTS (SELECT 1 FROM @TmpCoShip WHERE rowpointer = @CoShipRowPointer)
                   INSERT INTO @TmpCoShip (
                        qty_invoiced
                      , qty_returned
                      , upd_del_flag
                      , RowPointer)
                   VALUES (
                        @CoShipQtyInvoiced
                      , @CoShipQtyReturned
                      , 'U'
                      , @CoShipRowPointer)

               IF @CustomerPrintPackInv = 1 and @CoShipPackNum <> 0
               if NOT EXISTS (SELECT 1 FROM @TmpPckitem WHERE RowPointer IN (
               SELECT
                  pckitem.RowPointer
               FROM pckitem
               WHERE pckitem.pack_num = @CoShipPackNum
                 AND pckitem.co_line = @CoitemCoLine
                 AND pckitem.co_release = @CoitemCoRelease
                 AND pckitem.inv_num is NULL
               ))
                  INSERT INTO @TmpPckitem (
                       inv_num
                     , RowPointer)
                  SELECT
                       @InvHdrInvNum
                     , RowPointer
                  FROM pckitem
                  WHERE pckitem.pack_num = @CoShipPackNum
                    AND pckitem.co_line = @CoitemCoLine
                    AND pckitem.co_release = @CoitemCoRelease
                    AND pckitem.inv_num is NULL

               IF @CustomerPrintPackInv = 1 and @CoShipPackNum = 0
               if NOT EXISTS (SELECT 1 FROM @TmpPckitem WHERE RowPointer IN (
               SELECT
                  pckitem.RowPointer
               FROM pckitem
               WHERE pckitem.co_num = @CoitemCoNum
                 AND pckitem.co_line = @CoitemCoLine
                 AND pckitem.co_release = @CoitemCoRelease
                 AND pckitem.inv_num is NULL
               ))
                  INSERT INTO @TmpPckitem (
                       inv_num
                     , RowPointer)
                  SELECT
                       @InvHdrInvNum
                     , RowPointer
                  FROM pckitem
                  WHERE pckitem.co_num = @CoitemCoNum
                    AND pckitem.co_line = @CoitemCoLine
                    AND pckitem.co_release = @CoitemCoRelease
                    AND pckitem.inv_num is NULL
            END
            CLOSE      co_ship_Crs
            DEALLOCATE co_ship_Crs /* for each */

         END /* IF  @InvCred = 'I' */
         ELSE
         BEGIN
            SET @CoShipRowPointer  = NULL
            SET @CoShipShipDate    = NULL

            SELECT TOP 1 /* last */
                 @CoShipRowPointer  = co_ship.RowPointer
               , @CoShipOrigInvoice = co_ship.orig_inv_num
               , @CoShipReasonText  = co_ship.reason_text
               , @CoShipShipDate    = co_ship.ship_date
            FROM co_ship
            WHERE co_ship.co_num=@CoitemCoNum
            AND co_ship.co_line = @CoitemCoLine
            AND co_ship.co_release = @CoitemCoRelease
            AND (co_ship.do_num = '' OR co_ship.do_num IS NULL)
            AND (co_ship.shipment_id IS NULL OR (co_ship.shipment_id IS NOT NULL AND @PaymentMethod = 'C') OR @InvCred = 'C')
            AND co_ship.qty_returned > 0 -- ISSUE 162163 get the returned co_ship
            ORDER BY co_ship.date_seq DESC

            SET @InvItemOrigInvoice = @CoShipOrigInvoice
            SET @InvItemReasonText = @CoShipReasonText

            SET @TShipDate = CASE WHEN @CoShipRowPointer IS NOT NULL THEN @CoShipShipDate ELSE NULL END

            IF @TShipDate IS NOT NULL
            BEGIN
               SET @CoitemShipDate = @TShipDate
               SET @TShipDate = NULL
            END

            DECLARE co_ship_Crs CURSOR LOCAL STATIC FOR
            SELECT
                 co_ship.RowPointer
               , co_ship.qty_invoiced
               , co_ship.qty_shipped
               , co_ship.qty_returned
            FROM co_ship
            WHERE co_ship.co_num=@CoitemCoNum
              AND co_ship.co_line = @CoitemCoLine
              AND co_ship.co_release = @CoitemCoRelease
              AND co_ship.qty_returned  > 0
            OPEN co_ship_Crs
            WHILE @Severity = 0
            BEGIN
               FETCH co_ship_Crs INTO
                    @CoShipRowPointer
                  , @CoShipQtyInvoiced
                  , @CoShipQtyShipped
                  , @CoShipQtyReturned
               IF @@FETCH_STATUS = -1
                  BREAK

               SET @CoShipQtyInvoiced = ISNULL(@CoShipQtyInvoiced, 0)
               SET @CoShipQtyShipped  = ISNULL(@CoShipQtyShipped, 0)
               SET @CoShipQtyReturned = ISNULL(@CoShipQtyReturned, 0)

               SET @CoShipQtyInvoiced = @CoShipQtyInvoiced - @CoShipQtyReturned
               SET @CoShipQtyReturned = 0

               IF (@CoShipQtyInvoiced = 0 and @CoShipQtyShipped = 0 and @CoShipQtyReturned = 0 )
                  INSERT INTO @TmpCoShip (
                       upd_del_flag
                     , RowPointer)
                  VALUES (
                       'D'
                     , @CoShipRowPointer)
               ELSE
                  INSERT INTO @TmpCoShip (
                       qty_invoiced
                     , qty_returned
                     , upd_del_flag
                     , RowPointer)
                  VALUES (
                       @CoShipQtyInvoiced
                     , @CoShipQtyReturned
                     , 'U'
                     , @CoShipRowPointer)
            END
            CLOSE      co_ship_Crs
            DEALLOCATE co_ship_Crs
         END /* IF @InvCred = 'C' */

        IF @CoCustShipmentApprovalRequired = 1
        BEGIN
           DECLARE
            @Pcontrol_site          SiteType
            ,@Pcontrol_year         FiscalYearType
            ,@Pcontrol_period       FinPeriodType
            ,@Pcontrol_number       LastTranType 
     
           DECLARE co_approval_Crs CURSOR LOCAL STATIC FOR                       
            SELECT  posted_control_site
                  , posted_control_year
                  , posted_control_period
                  , posted_control_number 
            FROM co_ship_approval_log             
            WHERE co_num=@CoitemCoNum  AND co_line = @CoitemCoLine AND co_release = @CoitemCoRelease AND
              inv_num is null AND
              approval_date BETWEEN IsNull(@StartLastShipDate, approval_date) AND
                              IsNull (dbo.DayEndOf(@EndLastShipDate), approval_date)         
            OPEN co_approval_Crs
            WHILE @Severity = 0
            BEGIN
              FETCH co_approval_Crs INTO
                    @Pcontrol_site
                  , @Pcontrol_year
                  , @Pcontrol_period
                  , @Pcontrol_number
               IF @@FETCH_STATUS = -1
                  BREAK

              EXEC @Severity = dbo.ReverseSystemTransactionSp 'JournalEntries'
                                                   ,'AR'
                                                   ,@Pcontrol_site
                                                   ,@Pcontrol_year
                                                   ,@Pcontrol_period
                                                   ,@Pcontrol_number
                                                   ,NULL
                                                   ,@Infobar
            END

         CLOSE      co_approval_Crs
         DEALLOCATE co_approval_Crs                  
      END


         /* ASSIGN INV-NUM TO SERIAL FILE */
         IF @ItemSerialTracked = 1
         BEGIN
            delete @SerialTable

            insert into @SerialTable
            select serial.item, serial.ser_num, case when matltrack.qty > 0 then 1 else -1 end
            from matltrack
               inner join serial on
                  serial.item = matltrack.item
                  and serial.stat = @TStat
                  -- Skip already invoiced
                  and (@InvCred = 'C' -- credit memo
                     or (@InvCred = 'I' and serial.inv_num = '0') -- never invoiced
                     or (@InvCred = 'I' and serial.inv_num != '0'
                        and exists (select 1 from inv_item where inv_item.inv_num = serial.inv_num
                           and inv_item.co_num = serial.ref_num
                           and inv_item.co_line = serial.ref_line
                           and inv_item.co_release = serial.ref_release
                           and inv_item.qty_invoiced < 0)
                     ) -- last activity was a Credit Memo
                  )
               inner join ser_track on
                  ser_track.track_num = matltrack.track_num
                  and ser_track.ser_num = serial.ser_num
            where 1 = case when @InvCred = 'I' and matltrack.track_type in ('I', 'W') then 1
               when @InvCred = 'C' and matltrack.track_type = @TMatltype then 1
               else 0 end
            and matltrack.ref_type = 'O'
            and matltrack.ref_num = @CoitemCoNum
            and matltrack.ref_line_suf = @CoitemCoLine
            and matltrack.ref_release = @CoitemCoRelease
            and ((matltrack.track_link = @PackNum) or (@PackNum = 0))
            and (@CustomerOnePackInv = 1 or @CreateFromPackSlip = 0 or
               (@CustomerOnePackInv = 0 and @CreateFromPackSlip = 1
               and (exists (select 1 from @CoListPack as clp where clp.co_num = matltrack.ref_num and clp.pack_num = matltrack.track_link)))
                 or (matltrack.track_link is null
                  and exists (select 1 from pckitem where pckitem.co_num = matltrack.ref_num and pckitem.co_line = matltrack.ref_line_suf
                     and pckitem.co_release = matltrack.ref_release
                     and pckitem.pack_num between @StartPackNum and @EndPackNum))
                  )

            if @InvCred = 'I'
               delete from @SerialTable
               from @SerialTable dst
               inner join 
               (select item, ser_num from @SerialTable
               group by item, ser_num
               having sum(qty) = 0) st
               on dst.item = st.item and dst.ser_num = st.ser_num

            insert into @TmpSerial
            select distinct st.item, st.ser_num, @InvHdrInvNum
            from @SerialTable as st
            where not exists (select 1 from @TmpSerial as ts where ts.ser_num = st.ser_num and ts.item = st.item)
         END /* IF @ItemSerialTracked = 1 */

         /* PROCESS PREVIOUS PROGRESSIVE BILLINGS AGAINST EACH LINE ITEM */
         set @InvProExists = case when exists (select 1 from inv_pro where inv_pro.co_num = @CoitemCoNum
            and inv_pro.co_line = @CoitemCoLine) then 1 else 0 end

         IF @CoitemQtyReturned > 0 AND @InvCred = 'C'
         BEGIN
            SET @BilledFor = 0.0
            SET @BilledFor2 = 0.0
         END
         ELSE
         BEGIN
            SET @BilledFor = 
                (CASE WHEN @CoParmsUseAltPriceCalc = 1 THEN
                     ROUND(ROUND(@CoitemPrice * (1.0 - @CoitemDisc / 100), @CurrencyPlaces) * (@CoitemQtyShipped - @CoitemQtyInvoiced), @CurrencyPlaces) 
                 ELSE
                     ROUND((@CoitemQtyShipped - @CoitemQtyInvoiced) * @CoitemPrice * (1.0 - @CoitemDisc / 100), @CurrencyPlaces)
                 END)

            SET @BilledFor2 = 
                (CASE WHEN @CoParmsUseAltPriceCalc = 1 THEN
                    ROUND(@CoitemPrice * (1.0 - @CoitemDisc / 100), @CurrencyPlaces) * (@CoitemQtyShipped - @CoitemQtyInvoiced)
                 ELSE
                     (@CoitemQtyShipped - @CoitemQtyInvoiced) * @CoitemPrice * (1.0 - @CoitemDisc / 100)
                 END)
         END

         SET @BilledFor2 = ROUND((Case WHEN @BilledFor2 > 0 THEN @BilledFor2 ELSE 0 END), @CurrencyPlaces)

         /* 1. If this is the Final Shipment, apply the total amount
          *    of all prog bills remaining. If the prog bill remaining
          *    total more than the amount being invoiced, a credit memo
          *    will be issued.
          * 2. If the amount being billed for is LESS than the remaining
          *    progressive bills to be applied, ONLY apply the amount being
          *    billed for. EXAMPLE:  coitem.prg-bill-tot = $1,000
          *                          coitem.prg-bill-app =    400
          *                          billed-for          =    100
          *                            Only $100 would be applied and
          *                            the remaining $300 would be applied
          *                            towards the next shipment..
          * 3. Otherwise, apply the entire remaining amount to the invoice.
          *    EXAMPLE:  coitem.prg-bill-tot = $1,000
          *              coitem.prg-bill-app =    700
          *              billed-for          =    500
          *              Only $300 would be applied.  */

         SET @AmountToApply = CASE WHEN @CoitemQtyShipped >= @CoitemQtyOrdered
                                      THEN (@CoitemPrgBillTot - @CoitemPrgBillApp)
                                   ELSE CASE WHEN @InvCred = 'I' AND @BilledFor > 0
                                                THEN dbo.MinAmt(@BilledFor, @CoitemPrgBillTot - @CoitemPrgBillApp)
                                             WHEN @InvCred = 'I' AND @BilledFor < 0
                                                THEN dbo.MaxAmt(@BilledFor, @CoitemPrgBillTot - @CoitemPrgBillApp)
                                             ELSE dbo.MaxAmt(@BilledFor, - @CoitemPrgBillApp)
                                       END
                              END

         SET @AmountToApply2 = CASE WHEN @CoitemQtyShipped >= @CoitemQtyOrdered
                                       THEN (@CoitemPrgBillTot - @CoitemPrgBillApp)
                                    ELSE CASE WHEN @InvCred = 'I'
                                                 THEN dbo.MinAmt(@BilledFor2, @CoitemPrgBillTot - @CoitemPrgBillApp)
                                              ELSE dbo.MaxAmt(@BilledFor2, - @CoitemPrgBillApp)
                                         END
                               END

         if @CoitemQtyShipped >= @CoitemQtyOrdered
            set @ProgressiveRoundingAmt = CASE WHEN @AmountToApply = 0 THEN 0
                                               WHEN @CoitemPrgBillTot = 
                                                       (CASE WHEN @CoParmsUseAltPriceCalc = 1 THEN
                                                           ROUND( (ROUND(@CoitemPrice * (1.0 - @CoitemDisc / 100), @CurrencyPlaces) * @CoitemQtyShipped
                                                           * (1.0 - @CoDisc / 100.0)) , @CurrencyPlaces)
                                                        ELSE
                                                           ROUND( (ROUND(@CoitemQtyShipped * @CoitemPrice * (1.0 - @CoitemDisc / 100), @CurrencyPlaces) 
                                                           * (1.0 - @CoDisc / 100.0)) , @CurrencyPlaces)
                                                        END)
                                                  THEN (@AmountToApply - @BilledFor * (1.0 - @CoDisc / 100.0))
                                               ELSE 0 END
         else
            set @ProgressiveRoundingAmt = 0

         /* APPLY PARTIALLY APPLIED, PROGRESSIVELY BILLED AMOUNT */
         SET @TXInvProAmount = 0

         SELECT
            @TXInvProAmount = @TXInvProAmount + ISNULL(inv_pro.amount, 0)
         FROM inv_pro
         WHERE inv_pro.co_num = @CoitemCoNum
           AND inv_pro.co_line = @CoitemCoLine
           AND ISNULL(inv_pro.Applied, 0) = 1
           AND inv_pro.seq < 1000

         SET @PartiallyApplied = @CoitemPrgBillApp - @TXInvProAmount
         set @NoProg = case when @InvCred = 'C' and @PartiallyApplied = 0 and @InvProExists = 1 then 1 else 0 end

         /* APPLY NECESSARY PROGRESSIVELY BILLED AMOUNTS */
         SET @I = 0
         SET @AmountApplied = 0

         DECLARE inv_pro2_Crs CURSOR LOCAL STATIC FOR
         SELECT
              inv_pro.RowPointer
            , inv_pro.amount
         FROM inv_pro
         WHERE inv_pro.co_num = @CoitemCoNum
           AND inv_pro.co_line = @CoitemCoLine
           AND inv_pro.applied = 0
           AND inv_pro.seq < 1000
         ORDER BY inv_pro.seq

         OPEN inv_pro2_Crs
         WHILE @Severity = 0
         BEGIN
            FETCH inv_pro2_Crs INTO
                 @XInvProRowPointer
               , @XInvProAmount
            IF @@FETCH_STATUS = -1
                BREAK

            SET @XInvProAmount = ISNULL(@XInvProAmount, 0)

            SET @LeftToApply = @XInvProAmount - @PartiallyApplied
            IF @LeftToApply = 0.0
               CONTINUE

            if @CoitemQtyShipped >= @CoitemQtyOrdered
               set @AmountToApply = @AmountToApply
            else
               set @AmountToApply = round(@AmountToApply * (1.0 - @CoDisc / 100.0), @CurrencyPlaces)

            SET @TApp = CASE WHEN @LeftToApply > 0.0 THEN dbo.MinAmt(@LeftToApply, (@AmountToApply - @AmountApplied))
                             ELSE dbo.MaxAmt(@LeftToApply, (@AmountToApply - @AmountApplied))
                        END

            IF (@AmountToApply > 0.0 AND @AmountToApply > @AmountApplied)
            OR (@AmountToApply < 0.0 AND @AmountToApply < @AmountApplied)
            BEGIN
               SET @AmountApplied = @AmountApplied + @TApp
               SET @CoitemPrgBillApp = @CoitemPrgBillApp + @TApp

               IF (@TApp < 0.0 AND @CoitemPrgBillApp < @CoitemPrgBillTot AND @CoitemPrgBillApp - @TApp >= @CoitemPrgBillTot)
               OR (@TApp > 0.0 AND @CoitemPrgBillApp > @CoitemPrgBillTot)
                  SET @CoitemPrgBillApp = @CoitemPrgBillTot

               IF @TApp + @PartiallyApplied = @XInvProAmount
               BEGIN
                  INSERT INTO @TmpInvPro (
                       inv_num
                     , inv_seq
                     , co_num
                     , co_line
                     , seq
                     , amount
                     , description
                     , applied
                     , new
                     , RowPointer)
                  SELECT
                       inv_num
                     , inv_seq
                     , co_num
                     , co_line
                     , seq
                     , amount
                     , description
                     , 1
                     , 0
                     , RowPointer
                  FROM inv_pro
                  WHERE inv_pro.RowPointer = @XInvProRowPointer

                  SET @PartiallyApplied = 0.0
               END
            END -- IF (@AmountToApply > 0

            SET @TProgBill = 1

            /* inv-pro records on non-Progressive Invoices keep track of the
             * 'Less Previously Invoiced' lines of the Invoice, for reprinting.
             */
            IF @AmountToApply <> 0.0
            BEGIN
               --create inv_pro

               SET @I = @I + 1
               SET @InvProInvNum = @InvHdrInvNum
               SET @InvProCoNum = @CoitemCoNum
               SET @InvProCoLine = @CoitemCoLine
               /* Workaround
                * Set inv_pro.seq value for "Less Previously Invoiced" type rows to a high value, and
                * do not use those rows while evaluating inv_pro.amount.
                */
               SET @InvProSeq = @I + 1000
               SET @InvProAmount = @LeftToApply
               IF @InvProAmount < @XInvProAmount
                  SET @InvProDescription = @TextLessPreviouslyInvoiced + ' ' + @TextBalance
               ELSE
                  SET @InvProDescription = @TextLessPreviouslyInvoiced
               SET @InvProApplied = 0  /* so the SELECT statement above excludes it. */

               SET @InvProRowPointer = Newid()
               INSERT INTO @TmpInvPro(inv_num, co_num, co_line, seq, amount, description, applied, new, RowPointer)
               VALUES(@InvProInvNum, @InvProCoNum, @InvProCoLine, @InvProSeq,
                        @InvProAmount, @InvProDescription, @InvProApplied, 1, @InvProRowPointer)

            END
         END
         CLOSE      inv_pro2_Crs
         DEALLOCATE inv_pro2_Crs /* for each x-inv-pro */

         IF NOT EXISTS (SELECT 1 FROM @TmpProgbill WHERE rowpointer IN (
               SELECT
                  RowPointer
               FROM progbill
               WHERE progbill.co_num = @CoitemCoNum
                 AND progbill.co_line = @CoitemCoLine
                 AND CHARINDEX( progbill.invc_flag, 'YAN') <> 0
                 AND isnull(progbill.bill_amt, 0) > 0)) 
             INSERT INTO @TmpProgbill (
                  co_num
                , co_line
                , invc_flag
                , RowPointer
                , seq)
             SELECT
                  co_num
                , co_line
                , 'V'
                , RowPointer
                , seq
             FROM progbill
             WHERE progbill.co_num = @CoitemCoNum
               AND progbill.co_line = @CoitemCoLine
               AND CHARINDEX( progbill.invc_flag, 'YAN') <> 0
               AND isnull(progbill.bill_amt, 0) > 0

         IF @TProgBill = 0
            SET @AmountToApply = @AmountToApply2

         /* POST TO INVOICE HISTORY & EC SSD REPORT DATA (same file) */
         --Load inv_item for creation later

         SET @InvItemInvNum      = @InvHdrInvNum
         SET @InvItemInvSeq      = @InvHdrInvSeq
         SET @InvItemInvLine     = 0
         SET @InvItemCoNum       = @CoitemCoNum
         SET @InvItemCoLine      = @CoitemCoLine
         SET @InvItemCoRelease   = @CoitemCoRelease
         SET @InvItemItem        = @CoitemItem
         SET @InvItemDisc        = @CoitemDisc
         SET @InvItemPrice       = (CASE WHEN @CoParmsUseAltPriceCalc = 1 THEN ROUND(@CoitemPrice * (1.0 - @CoitemDisc / 100.0), @CurrencyPlaces)
                                    ELSE @CoitemPrice * (1.0 - @CoitemDisc / 100.0)
                                    END)
         SET @InvItemProcessInd  = @CoitemProcessInd
         SET @InvItemConsNum     = @CoitemConsNum
         SET @InvItemTaxCode1    = @CoitemTaxCode1
         SET @InvItemTaxCode2    = @CoitemTaxCode2
         SET @InvItemTaxDate     =
            (CASE WHEN ((@InvHdrInvDate < @TaxparmsLastSsdReport)
                        and @TaxparmsLastSsdReport IS NOT NULL ) then
                        @TaxparmsLastSsdReport
                  ELSE @InvHdrInvDate END)
         SET @InvItemExciseTaxPercent = @ItemExciseTaxPercent

         IF @CoEdiType = 'S'
            SET @InvItemCustPo = @CoitemCustPo

         IF @InvCred = 'I'
         BEGIN
            SET @InvItemQtyInvoiced = @QtyToInvoice

            SET @CoitemQtyInvoiced = @CoitemQtyInvoiced + @QtyToInvoice
            IF @TMatlCost <> 0 and @InvItemQtyInvoiced <> 0
               SET @InvItemCost = @TMatlCost / @InvItemQtyInvoiced

         END
         ELSE
         BEGIN
            SET @InvItemQtyInvoiced = - @CoitemQtyReturned

            /* Search matltran file until the matltrans created when the item
             * was returned are found. Get the total return cost for the item
             * from the matltran record(s) and post THIS cost to the inv-item
             * credit memo record. */
            SET @TCreditMemoCost = 0
            SET @TReturned = 0

            SET @MatltranRowPointer = NULL
            SET @MatltranQty        = 0
            SET @MatltranCost       = 0

            DECLARE matltranCrs CURSOR LOCAL STATIC FOR
            SELECT matltran.RowPointer, matltran.qty, matltran.cost
            FROM matltran
            WHERE matltran.item = @CoitemItem
               AND matltran.trans_type = 'W'
               AND matltran.ref_type = 'O'
               AND matltran.ref_num = @CoitemCoNum
               AND matltran.ref_line_suf = @CoitemCoLine
               AND matltran.ref_release = @CoitemCoRelease
            ORDER BY matltran.trans_num DESC
            OPEN matltranCrs
            FETCH matltranCrs into
                 @MatltranRowPointer
               , @MatltranQty
               , @MatltranCost

            SET @MatltranQty        = ISNULL(@MatltranQty, 0)
            SET @MatltranCost       = ISNULL(@MatltranCost, 0)

            IF (@MatltranRowPointer IS NULL)
            BEGIN

               SET @TCreditMemoCost = CASE WHEN @CoitemQtyShipped = 0 THEN @CoitemCost
                                           ELSE (@CoitemCgsTotal / @CoitemQtyShipped) END
               SET @Infobar = NULL
               EXEC @Severity = dbo.MsgAppSp @Infobar OUTPUT, 'W=NoExistForIs3'
                  , '@matltran'
                  , '@matltran.trans_type'
                  , '@:MatlTransType:WC'
                  , '@coitem'
                  , '@coitem.co_num'
                  , @CoitemCoNum
                  , '@coitem.co_line'
                  , @CoitemCoLine
                  , '@coitem.co_release'
                  , @CoitemCoRelease

               SET @TQtyRemain = 0

            END /* IF (@MatltranRowPointer IS NULL) */
            ELSE
            BEGIN
               IF @CoitemQtyReturned < @MatltranQty
               BEGIN
                  SET @TQtyRemain = 0
                  SET @TCreditMemoCost = @MatltranCost * @CoitemQtyReturned
                  SET @TReturned = @CoitemQtyReturned
               END
               ELSE
               BEGIN
                  SET @TQtyRemain = @CoitemQtyReturned - @MatltranQty
                  SET @TCreditMemoCost = @TCreditMemoCost + (@MatltranCost * @MatltranQty)
                  SET @TReturned = @TReturned + @MatltranQty
               END
               WHILE @TQtyRemain > 0
               BEGIN
                  FETCH matltranCrs INTO
                       @MatltranRowPointer
                     , @MatltranQty
                     , @MatltranCost

                  SET @MatltranQty        = ISNULL(@MatltranQty, 0)
                  SET @MatltranCost       = ISNULL(@MatltranCost, 0)

                  IF @MatltranRowPointer IS NULL OR @@fetch_status != 0
                  BEGIN
                     IF @CoitemQtyShipped > 0
                        SET @TCreditMemoCost = @CoitemCgsTotal / @CoitemQtyShipped
                     ELSE
                        SET @TCreditMemoCost = @CoitemCgsTotal
                     SET @Infobar = NULL

                     EXEC @Severity = dbo.MsgAppSp @Infobar OUTPUT, 'W=NoExistForIs3'
                        , '@matltran'
                        , '@matltran.trans_type'
                        , '@:MatlTransType:WC'
                        , '@coitem'
                        , '@coitem.co_num'
                        , @CoitemCoNum
                        , '@coitem.co_line'
                        , @CoitemCoLine
                        , '@coitem.co_release'
                        , @CoitemCoRelease

                     SET @TQtyRemain = 0
                  END /* if not available */
                  ELSE
                  BEGIN
                     SET @TQtyRemain = @TQtyRemain - @MatltranQty
                     SET @TCreditMemoCost = @TCreditMemoCost + (@MatltranCost * @MatltranQty)
                     SET @TReturned = @TReturned + @MatltranQty
                  END
               END /* do while */
            END /* else do */
            CLOSE matltranCrs
            DEALLOCATE matltranCrs

            IF @TReturned <> 0
               SET @TCreditMemoCost = @TCreditMemoCost / @TReturned

            SET @InvItemCost = @TCreditMemoCost
            SET @CoitemQtyInvoiced = @CoitemQtyInvoiced - @CoitemQtyReturned
            SET @CoitemQtyReturned = 0
         END /* IF @InvCred = 'C' */

         /* UPDATE SALES SUMMARY INFORMATION */
         SET @TInvAmount = @InvItemPrice * @InvItemQtyInvoiced
         EXEC @Severity = dbo.CurrCnvtSp
            @CustaddrCurrCode, 0, 0, 1, NULL, NULL, NULL, NULL, NULL,
            @InvHdrExchRate OUTPUT, @Infobar OUTPUT, @TInvAmount,
            @DPrice OUTPUT, @Site = @ParmsSite
         , @DomCurrCode = @CurrparmsCurrCode

         IF @Severity <> 0
            GOTO EXIT_SP

         update @SarbWrt
         set price = price + @DPrice
         , qty_invoiced = qty_invoiced + @InvItemQtyInvoiced
         where item = @InvItemItem
         and inv_date = @InvHdrInvDate

         if @@rowcount = 0
            insert into @SarbWrt
            values (@InvItemItem, @InvHdrInvDate, @DPrice, @InvItemQtyInvoiced)

         /* POST TO ITEM MASTER */

         exec @Severity = dbo.GetumcfSp
           @OtherUM    = @CoitemUM
         , @Item       = @CoitemItem
         , @VendNum    = @CoCustNum
         , @Area       = 'C'
         , @ConvFactor = @ConvFactor OUTPUT
         , @Infobar    = @Infobar OUTPUT
         , @Site       = @ParmsSite
         set @InvItemQtyInvoicedConv = round(dbo.UomConvQty (@InvItemQtyInvoiced, @ConvFactor, 'From Base'), @InvparmsPlacesQtyUnit)
         set @InvItemPriceConv = dbo.UomConvAmt (@InvItemPrice, @ConvFactor, 'From Base')
         SET @TLineNet = round((CASE WHEN @CoParmsUseAltPriceCalc = 1 THEN ROUND(@InvItemQtyInvoicedConv, @CurrencyPlaces)
                         ELSE @InvItemQtyInvoicedConv END) * @InvItemPriceConv, @CurrencyPlaces) + @ProgressiveRoundingAmt
         SET @TLineTot = round((CASE WHEN @CoParmsUseAltPriceCalc = 1 THEN ROUND(@CoitemPriceConv, @CurrencyPlaces)
                         ELSE @CoitemPriceConv END)*@InvItemQtyInvoicedConv, @CurrencyPlaces)
         SET @TSubTotFull = @TSubTotFull + @TLineNet

         if @CustaddrCurrCode = @CurrparmsCurrCode
            set @DAmt = @TLineNet
         else
            EXEC @Severity = dbo.CurrCnvtSp @CustaddrCurrCode, 0, 0,
               1, null, null, null, null, null, @InvHdrExchRate OUTPUT
               , @Infobar OUTPUT, @TLineNet, @DAmt output
               , @Site = @ParmsSite
            , @DomCurrCode = @CurrparmsCurrCode

         IF @Severity <> 0
            GOTO EXIT_SP

         IF @NonInventoryItem <>1
          BEGIN
          -- UPDATE Item
           IF NOT EXISTS (SELECT * FROM @TmpItem AS TI WHERE TI.RowPointer = @ItemRowPointer)
              INSERT INTO @TmpItem (
                  last_inv
                , RowPointer
                )
              VALUES (
                  @InvDate
                , @ItemRowPointer)

           -- UPDATE Itemwhse
           IF EXISTS (SELECT * FROM @TmpItemwhse AS TI WHERE TI.item = @ItemItem AND TI.whse = @CoitemWhse)
              UPDATE @TmpItemwhse
                 SET sales_ptd = sales_ptd + @DAmt
                   , sales_ytd = sales_ytd + @DAmt
              WHERE item = @ItemItem AND whse = @CoitemWhse
           ELSE
              INSERT INTO @TmpItemwhse (
                  item
                , whse
                , sales_ptd
                , sales_ytd
                , RowPointer)
              SELECT
                  item
                , whse
                , @DAmt
                , @DAmt
                , RowPointer
              FROM itemwhse
              WHERE itemwhse.item = @ItemItem AND itemwhse.whse = @CoitemWhse
          END

         /* ACCUMULATE TAXABLES FOR THIS LINE ITEM (into w-tax-base workfile) */

         SET @OLvlDiscLineNet = @TLineNet * (1.0 - @CoDisc / 100.0)
         SET @Infobar = NULL
         SET @TTaxablePrice= CASE WHEN @CusttypeRowPointer IS NOT NULL
                                  THEN @CusttypeTaxablePrice
                                  ELSE 'W'
                             END

         SET @TaxInclDiscount      = 0
         SET @Tax1OnAmount         = 0.0
         SET @Tax2OnAmount         = 0.0
         SET @Tax1OnDiscAmount     = 0.0
         SET @Tax2OnDiscAmount     = 0.0
         SET @Tax1OnUndiscAmount   = 0.0
         SET @Tax2OnUndiscAmount   = 0.0
         SET @TotalTaxOnDiscAmount = 0.0
         SET @DiscAmountInclTax    = 0.0
         SET @DiscAmountInclTax2   = 0.0

         IF @CoIncludeTaxInPrice = 1
         BEGIN
            if @NoProg = 0
            begin
               SET @TLineNet = @TLineNet - @AmountToApply
               SET @TLineTot = @TLineTot - @AmountToApply
            end
            SET @OLvlDiscLineNet = @OLvlDiscLineNet - @AmountToApply

            SET @DiscAmountInclTax = @TLineTot - @TLineNet
            SET @DiscAmountInclTax2 = @TLineTot - @OLvlDiscLineNet
            set @WholesalePrice = case when @TTaxablePrice = 'W' then @ItemUWsPrice * @InvItemQtyInvoiced else null end

            -- Separate amount including tax to amount without tax and tax amounts
            EXEC @Severity = dbo.TaxPriceSeparationSp
                 @InvType                 = 'R'
               , @Type                    = 'I'
               , @TaxCode1                = @InvItemTaxCode1
               , @TaxCode2                = @InvItemTaxCode2
               , @HdrTaxCode1             = @InvHdrTaxCode1
               , @HdrTaxCode2             = @InvHdrTaxCode2
               , @Amount                  = @OLvlDiscLineNet -- @AmountWithTax - Discount
               , @UndiscAmount            = @TLineTot -- @AmountWithTax (includes Discount)
               , @CurrCode                = @CustaddrCurrCode
               , @ExchRate                = @InvHdrExchRate
               , @UseExchRate             = @InvHdrUseExchRate
               , @Places                  = @CurrencyPlaces
               , @InvDate                 = @InvHdrInvDate
               , @TermsCode               = @InvHdrTermsCode
               , @AmountWithoutTax        = @OLvlDiscLineNet    OUTPUT
               , @UndiscAmountWithoutTax  = @TLineTot           OUTPUT
               , @Tax1OnAmount            = @Tax1OnAmount       OUTPUT
               , @Tax2OnAmount            = @Tax2OnAmount       OUTPUT
               , @Tax1OnUndiscAmount      = @Tax1OnUndiscAmount OUTPUT
               , @Tax2OnUndiscAmount      = @Tax2OnUndiscAmount OUTPUT
               , @Infobar                 = @Infobar            OUTPUT
               , @WholesalePrice = @WholesalePrice

            IF @Severity <> 0
               GOTO EXIT_SP

            set @AccumTax1 = @AccumTax1 + @Tax1OnAmount
            set @AccumTax2 = @AccumTax2 + @Tax2OnAmount

            /* If CO is set as Price Included Tax and if dicounts are involved
             * then the discount was applied on Price Including Tax.
             * If discounts are not taxed then tax portion of discount needs to be
             * added to Sales amount.  To find that out find if there is a difference
             * between @Tax1OnAmount + @Tax1OnAmount (tax on discounted amount)
             * and @Tax1OnUndiscAmount + @Tax1OnUndiscAmount (tax on undiscounted amount).
             * Find the tax on Discount amount for this line and add this to Sales amount.
             */
            IF (@Tax1OnUndiscAmount + @Tax2OnUndiscAmount) - (@Tax1OnAmount + @Tax2OnAmount) = 0.0
               SET @TaxInclDiscount = 0
            ELSE
               SET @TaxInclDiscount = 1

            -- Find the tax on Discount amount to be added to Sales amount.
            EXEC @Severity = dbo.TaxPriceSeparationSp
                 @InvType                 = 'R'
               , @Type                    = 'I'
               , @TaxCode1                = @InvItemTaxCode1
               , @TaxCode2                = @InvItemTaxCode2
               , @HdrTaxCode1             = @InvHdrTaxCode1
               , @HdrTaxCode2             = @InvHdrTaxCode2
               , @Amount                  = @DiscAmountInclTax2
               , @UndiscAmount            = @DiscAmountInclTax2
               , @CurrCode                = @CustaddrCurrCode
               , @ExchRate                = @InvHdrExchRate
               , @UseExchRate             = @InvHdrUseExchRate
               , @Places                  = @CurrencyPlaces
               , @InvDate                 = @InvHdrInvDate
               , @TermsCode               = @InvHdrTermsCode
               , @AmountWithoutTax        = @xAmount1         OUTPUT
               , @UndiscAmountWithoutTax  = @xAmount1         OUTPUT
               , @Tax1OnAmount            = @Tax1OnDiscAmount OUTPUT
               , @Tax2OnAmount            = @Tax2OnDiscAmount OUTPUT
               , @Tax1OnUndiscAmount      = @xAmount1         OUTPUT
               , @Tax2OnUndiscAmount      = @xAmount1         OUTPUT
               , @Infobar                 = @Infobar          OUTPUT
               , @WholesalePrice = @WholesalePrice

            IF @Severity <> 0
               GOTO EXIT_SP

            if @TaxInclDiscount = 1
            begin
               set @AccumTax1 = @AccumTax1 + @Tax1OnDiscAmount
               set @AccumTax2 = @AccumTax2 + @Tax2OnDiscAmount
            end

            SET @TotalTaxOnDiscAmount = @Tax1OnDiscAmount + @Tax2OnDiscAmount
            SET @TaxBaseAmountToApply = 0
            SET @TaxBaseTLineTot = @TLineTot

         END -- IF @CoIncludeTaxInPrice = 1
      ELSE
      BEGIN
         SET @TaxBaseAmountToApply = case when @InvCred = 'I' then @AmountToApply else 0 end
         SET @TaxBaseTLineTot = @TLineTot

         /* Once the sales tax has been calculated on the total value of the
          * items shipped for this line/release on this invoice, subtract
          * the amount-to-apply (amount to be deducted from the line/rel total
          * price due to prog bills) from the net amount and net total. */
         if @NoProg = 0
         begin
            SET @TLineNet = @TLineNet - @AmountToApply
            SET @TLineTot = @TLineTot - @AmountToApply
         end
      END
      
      IF @InvCred = 'I'
      BEGIN
         --Find the Promotion Type that met.
         SET @SumProAmount = 0
         SELECT @CorpCust        = adr.corp_cust
               ,@CampaignID      = opp.campaign_id
         FROM co
         lEFT JOIN custaddr AS adr ON co.cust_num = adr.corp_cust and co.cust_seq = 0
         LEFT JOIN opportunity AS opp on opp.opp_id = co.opp_id
         WHERE co.co_num = @InvItemCoNum

         Declare PromCodeCrs cursor local static for
         SELECT pro.promotion_code,pro.rebate_number_periods,pro.rebate_redemption_rate
               ,pro.deferred_rev_acct,pro.deferred_rev_acct_unit1,pro.deferred_rev_acct_unit2,pro.deferred_rev_acct_unit3,pro.deferred_rev_acct_unit4
               ,pro.rebate_fair_value_type,pro.rebate_fair_value
         FROM price_promotion pro
         WHERE  (pro.cust_num = @CoCustNum                 OR pro.cust_num IS NULL)
                  AND (pro.cust_type = @CustomerCustType   OR pro.cust_type IS NULL)
                  AND (pro.corp_cust = @CorpCust           OR pro.corp_cust IS NULL)
                  AND (pro.slsman = @CoSlsman              OR pro.slsman IS NULL)
                  AND (pro.end_user_type = @CoEndUserType  OR pro.end_user_type IS NULL)                  
                  AND (pro.cust_seq = @CoCustSeq           OR pro.cust_seq IS NULL)
                  AND (pro.item = @CoitemItem              OR pro.item IS NULL)
                  AND (pro.whse = @CoitemWhse              OR pro.whse IS NULL)
                  AND (pro.product_code = @ItemProductCode OR pro.product_code IS NULL)
                  AND (pro.campaign_id = @CampaignID       OR pro.campaign_id IS NULL)
                  AND (@ArinvInvDate >= pro.effect_date   AND @ArinvInvDate <= pro.exp_date)
                  AND pro.promotion_type = N'R'
         Open PromCodeCrs
         While @Severity = 0
         begin
            Fetch PromCodeCrs into
              @PromotionCode
            , @Rebatenps
            , @RebateRedemptionRate
            , @Deferacct
            , @DeferacctUnit1
            , @DeferacctUnit2
            , @DeferacctUnit3
            , @DeferacctUnit4
            , @RebateFairValueType
            , @RebateFairValue
         
            IF @@fetch_status != 0
               break

            IF @Deferacct IS NULL
            BEGIN
               SET @Deferacct = @ArparmsDeferacct
               SET @DeferacctUnit1 = @ArparmsDeferacctUnit1
               SET @DeferacctUnit2 = @ArparmsDeferacctUnit2
               SET @DeferacctUnit3 = @ArparmsDeferacctUnit3
               SET @DeferacctUnit4 = @ArparmsDeferacctUnit4            
            END
            
            IF @RebateFairValueType = 'A' --AMOUNT
            BEGIN
               SET @ProAmount = @RebateFairValue * @CoShipQtyInvoiced
            END
            ELSE                          --RATE
            BEGIN
               SET @ProAmount = @RebateFairValue * (@CoitemPrice * @CoShipQtyInvoiced)
            END
              
            SET @DEarnedRebateAmount = 0

            EXEC @Severity = dbo.CurrCnvtSp
               @CurrCode     = @CustaddrCurrCode,
               @FromDomestic = 0,
               @UseBuyRate   = 0,
               @RoundResult  = 1,
               @Date         = NULL,
               @TRate        = @TRate OUTPUT,
               @Infobar      = @Infobar OUTPUT,
               @Amount1      = @ProAmount,
               @Result1      = @DEarnedRebateAmount OUTPUT,
               @Site         = @ParmsSite
       
            IF @Severity <> 0
               GOTO EXIT_SP
            
           SET @DEarnedRebateAmount = ROUND(@DEarnedRebateAmount, @CurrencyPlaces)
           --ExpDate
           SET @ExpDate = NULL
           
           IF ISNULL(@Rebatenps, 0) <> 0
           BEGIN
              select @FiscalYear = FiscalYear,@Period = Period from (
                select ROW_NUMBER() OVER(ORDER BY FiscalYear ASC,Period ASC) as RowNumber,FiscalYear, Period
                   from dbo.PeriodsAllView where site=@ParmsSite and (FiscalYear > dbo.GetFiscalYear() OR (FiscalYear = dbo.GetFiscalYear() AND Period > dbo.GetPeriod(@ArinvInvDate)))
              )  AS TmpPeriods
              where RowNumber = @Rebatenps
              
              SELECT @ExpDate = dbo.GetPeriodEndDate2(@Period,@FiscalYear)
              
              EXEC @Severity = DateChkSp
                @PDate         = @ExpDate
              , @FieldLabel    = '@earned_rebate.exp_date'
              , @Infobar       = @Infobar            OUTPUT
              , @PromptMsg     = @PromptMsg          OUTPUT
              , @PromptButtons = @PromptButtons      OUTPUT
                
              IF @Severity <> 0
                 GOTO EXIT_SP              
            END
       
            IF @DEarnedRebateAmount > 0  
               INSERT INTO earned_rebate
                  (
                         [status]
                       , [promotion_code]
                       , [cust_num]
                       , [inv_num]
                       , [inv_seq]
                       , [inv_line]
                       , [ref_type]
                       , [ref_num]
                       , [ref_line]
                       , [ref_release]
                       , [credit_memo_num]
                       , [effect_date]
                       , [exp_date]
                       , [deferred_rev_acct]
                       , [deferred_rev_acct_unit1]
                       , [deferred_rev_acct_unit2]
                       , [deferred_rev_acct_unit3]
                       , [deferred_rev_acct_unit4]
                       , [dom_amount] )
                  SELECT 
                         'P'
                       , @PromotionCode
                       , @ArinvCustNum
                       , @InvItemInvNum
                       , @InvItemInvSeq
                       , @InvItemInvLine
                       , 'O'
                       , @InvItemCoNum
                       , @InvItemCoLine
                       , @InvItemCoRelease
                       , NULL
                       , @ArinvInvDate
                       , @ExpDate
                       , @Deferacct
                       , @DeferacctUnit1
                       , @DeferacctUnit2
                       , @DeferacctUnit3
                       , @DeferacctUnit4
                       , @DEarnedRebateAmount

            --insert into @TmpArinvd
            SET @DEarnedRebateAmount = @DEarnedRebateAmount * @RebateRedemptionRate
            SET @DEarnedRebateAmount = ROUND(@DEarnedRebateAmount, @CurrencyPlaces)
            
            IF @Deferacct is not null and @DEarnedRebateAmount > 0
            Begin
               IF EXISTS (SELECT 1 FROM @TmpArinvd WHERE inv_num = @InvItemInvNum AND cust_num = @ArinvCustNum 
                                 AND acct=@Deferacct AND ISNULL(acct_unit1,'') = ISNULL(@DeferacctUnit1, '') 
                                                     AND ISNULL(acct_unit2,'') = ISNULL(@DeferacctUnit2, '') 
                                                     AND ISNULL(acct_unit3,'') = ISNULL(@DeferacctUnit3, '') 
                                                     AND ISNULL(acct_unit4,'') = ISNULL(@DeferacctUnit4, ''))
               BEGIN
                  UPDATE @TmpArinvd SET amount = amount + @DEarnedRebateAmount
                  WHERE inv_num = @InvItemInvNum AND cust_num = @ArinvCustNum 
                  AND acct=@Deferacct AND ISNULL(acct_unit1,'') = ISNULL(@DeferacctUnit1, '') 
                                      AND ISNULL(acct_unit2,'') = ISNULL(@DeferacctUnit2, '') 
                                      AND ISNULL(acct_unit3,'') = ISNULL(@DeferacctUnit3, '') 
                                      AND ISNULL(acct_unit4,'') = ISNULL(@DeferacctUnit4, '')
               END
               ELSE
               BEGIN
                  SET @ArinvdRowPointer = NewId()
                  SET @TDistSeq = @TDistSeq + 5
                  SET @ArinvdDistSeq = @TDistSeq
                  INSERT INTO @TmpArinvd (
                                            cust_num
                                          , inv_num
                                          , inv_seq
                                          , dist_seq
                                          , acct
                                          , acct_unit1
                                          , acct_unit2
                                          , acct_unit3
                                          , acct_unit4
                                          , amount
                                          , new
                                          , RowPointer)
                  SELECT 
                       @ArinvCustNum
                     , @InvItemInvNum
                     , @InvItemInvSeq
                     , @TDistSeq
                     , @Deferacct
                     , @DeferacctUnit1
                     , @DeferacctUnit2
                     , @DeferacctUnit3
                     , @DeferacctUnit4
                     , @DEarnedRebateAmount
                     , 1
                     , @ArinvdRowPointer
               END
               SET @SumProAmount = @SumProAmount + @DEarnedRebateAmount
            End
         END
         Close PromCodeCrs
         Deallocate PromCodeCrs
      END
      
         /* POST TO PROJECT */
         IF @CoitemRefType = 'K' AND @CoitemRefNum > ''
         BEGIN
            EXEC @Severity = dbo.ProjsaleSp
               @CoitemRefNum,       /* Project */
               @CoitemRefLineSuf,  /* Task */
               @CoitemCoNum,
               @CoitemCoLine,
               @CoitemCoRelease,
               @InvHdrInvDate,
               @TLineTot,
               @CustaddrCurrCode,
               @InvHdrExchRate,
               @Infobar OUTPUT

            IF @Severity <> 0
               GOTO EXIT_SP
         END
         
         
         SET @DistacctRowPointer = dbo.FndDist(@CoitemItem, @CoitemWhse)
         IF @DistacctRowPointer IS NOT NULL
         BEGIN
            SET @DistacctSurchargeAcct       = NULL
            SET @DistacctSurchargeAcctUnit1  = NULL
            SET @DistacctSurchargeAcctUnit2  = NULL
            SET @DistacctSurchargeAcctUnit3  = NULL
            SET @DistacctSurchargeAcctUnit4  = NULL
            SELECT
                 @DistacctSurchargeAcct       = distacct.surcharge_acct
               , @DistacctSurchargeAcctUnit1  = distacct.surcharge_acct_unit1
               , @DistacctSurchargeAcctUnit2  = distacct.surcharge_acct_unit2
               , @DistacctSurchargeAcctUnit3  = distacct.surcharge_acct_unit3
               , @DistacctSurchargeAcctUnit4  = distacct.surcharge_acct_unit4 
            FROM distacct with (readuncommitted)
            WHERE distacct.RowPointer = @DistacctRowPointer

         END
         IF @CoEndUserType <> ''
            BEGIN
            SET @EndtypeSurchargeAcct       = NULL
            SET @EndtypeSurchargeAcctUnit1  = NULL
            SET @EndtypeSurchargeAcctUnit2  = NULL
            SET @EndtypeSurchargeAcctUnit3  = NULL
            SET @EndtypeSurchargeAcctUnit4  = NULL
            SELECT
               @EndtypeRowPointer       = endtype.RowPointer
               
               , @EndtypeSurchargeAcct      = endtype.surcharge_acct
               , @EndtypeSurchargeAcctUnit1 = endtype.surcharge_acct_unit1
               , @EndtypeSurchargeAcctUnit2 = endtype.surcharge_acct_unit2
               , @EndtypeSurchargeAcctUnit3 = endtype.surcharge_acct_unit3
               , @EndtypeSurchargeAcctUnit4 = endtype.surcharge_acct_unit4
      
            FROM endtype with (readuncommitted)
            WHERE endtype.end_user_type = @CoEndUserType
         END
         
         IF @SurchargeAcct IS NULL  
         BEGIN  
            SET @SurchargeAcct            = @EndtypeSurchargeAcct  
            SET @SurchargeAcctUnit1       = @EndtypeSurchargeAcctUnit1  
            SET @SurchargeAcctUnit2       = @EndtypeSurchargeAcctUnit2  
            SET @SurchargeAcctUnit3       = @EndtypeSurchargeAcctUnit3  
            SET @SurchargeAcctUnit4       = @EndtypeSurchargeAcctUnit4  
         END  
         IF @SurchargeAcct IS NULL  
         BEGIN  
            SET @SurchargeAcct            = @DistacctSurchargeAcct  
            SET @SurchargeAcctUnit1       = @DistacctSurchargeAcctUnit1  
            SET @SurchargeAcctUnit2       = @DistacctSurchargeAcctUnit2  
            SET @SurchargeAcctUnit3       = @DistacctSurchargeAcctUnit3  
            SET @SurchargeAcctUnit4       = @DistacctSurchargeAcctUnit4  
         END  
         IF @SurchargeAcct IS NULL  
         BEGIN  
            SET @SurchargeAcct            = @ArparmsSurchargeAcct  
            SET @SurchargeAcctUnit1       = @ArparmsSurchargeAcctUnit1  
            SET @SurchargeAcctUnit2       = @ArparmsSurchargeAcctUnit2  
            SET @SurchargeAcctUnit3       = @ArparmsSurchargeAcctUnit3  
            SET @SurchargeAcctUnit4       = @ArparmsSurchargeAcctUnit4  
         END

         set @LineSurcharge = 0
         set @InvSurcharge = 0
         set @CoSurcharge = 0

         IF EXISTS ( SELECT 1 FROM item WHERE item.item = @CoitemItem AND item.item_content = 1)
         BEGIN
            DECLARE   @CurrDate             DateTimeType
                    , @TaxDate              DateType
                    SET @CurrDate     = dbo.GetSiteDate(GETDATE())                      
            SELECT TOP 1  
             @RuleEffectDate = effect_date  
             FROM cust_surcharge_rule  
            WHERE cust_num  = @CoCustNum  
              AND cust_seq    = @CoCustSeq 
              AND effect_date <= @CurrDate
            ORDER BY effect_date DESC
            
            SELECT @TaxDate = tax_date
              FROM inv_hdr
             WHERE inv_num = @InvItemInvNum AND inv_seq = @InvItemInvSeq
            
                     DELETE FROM @Surcharges

                     INSERT @Surcharges EXEC dbo.GetItemContentSp
                                         @CoitemItem
                                       , 'O'
                                       , @CoitemCoNum
                                       , @CoitemCoLine
                                       , @CoitemCoRelease
                                       , @InvItemInvNum
                                       
                     
                     INSERT INTO inv_item_surcharge(  
                                   inv_num
                                 , inv_seq
                                 , inv_line
                                 , co_num
                                 , co_line
                                 , co_release
                                 , surcharge_seq
                                 , item_content
                                 , item_content_factor
                                 , base_price
                                 , rule_effect_date
                                 , exchange_name
                                 , surcharge
                                 , surcharge_acct
                                 , surcharge_acct_unit1
                                 , surcharge_acct_unit2
                                 , surcharge_acct_unit3
                                 , surcharge_acct_unit4
                                 , tax_code1
                                 , tax_code2
                                 , tax_date
                                    )
                                 SELECT
                                   @InvItemInvNum
                                 , @InvItemInvSeq
                                 , @InvItemInvLine
                                 , @InvItemCoNum
                                 , @CoitemCoLine
                                 , @CoitemCoRelease
                                 , ROW_NUMBER() OVER ( ORDER BY ItemContent)
                                 , ItemContent
                                 , ItemContentFactor
                                 , BasePrice
                                 , @RuleEffectDate
                                 , ExchangeName
                                 , round(Surcharge * @InvItemQtyInvoiced, @CurrencyPlaces)
                                 , @SurchargeAcct
                                 , @SurchargeAcctUnit1
                                 , @SurchargeAcctUnit2
                                 , @SurchargeAcctUnit3
                                 , @SurchargeAcctUnit4
                                 , @InvItemTaxCode1
                                 , @InvItemTaxCode2
                                 , @TaxDate
                                 FROM @Surcharges
                                                
            SELECT @LineSurcharge = ISNULL(SUM(Surcharge),0) FROM inv_item_surcharge WHERE co_num = @InvItemCoNum AND inv_num = @InvItemInvNum AND co_line = @CoitemCoLine AND co_release = @CoitemCoRelease
            SELECT @InvSurcharge = ISNULL(SUM(Surcharge),0) FROM inv_item_surcharge WHERE co_num = @InvItemCoNum AND inv_num = @InvItemInvNum
            SELECT @CoSurcharge = ISNULL(SUM(Surcharge),0)  FROM inv_item_surcharge WHERE co_num = @InvItemCoNum
            
            IF @SurchargeAcct IS NOT NULL AND @LineSurcharge <> 0.0
               BEGIN
                  SET @ArinvdRowPointer = NULL
                  SET @ArinvdAmount     = 0

                  

                  IF @ArinvdRowPointer IS NULL
                  BEGIN
                     SET @TDistSeq = @TDistSeq + 5

                     SET @ArinvdRowPointer = newid()
                     SET @ArinvdCustNum    = @ArinvCustNum
                     SET @ArinvdInvNum     = @ArinvInvNum
                     SET @ArinvdInvSeq     = @ArinvInvSeq
                     SET @ArinvdDistSeq    = @TDistSeq
                     SET @ArinvdAcct       = @SurchargeAcct
                     SET @ArinvdAcctUnit1  = @SurchargeAcctUnit1
                     SET @ArinvdAcctUnit2  = @SurchargeAcctUnit2
                     SET @ArinvdAcctUnit3  = @SurchargeAcctUnit3
                     SET @ArinvdAcctUnit4  = @SurchargeAcctUnit4
                     SET @ArinvdAmount     = @LineSurcharge

                     INSERT INTO @TmpArinvd (
                                   RowPointer
                                 , cust_num
                                 , inv_num
                                 , inv_seq
                                 , dist_seq
                                 , acct
                                 , acct_unit1
                                 , acct_unit2
                                 , acct_unit3
                                 , acct_unit4
                                 , amount
                                 , new
                                 ) VALUES (
                                   @ArinvdRowPointer
                                 , @ArinvdCustNum
                                 , @ArinvdInvNum
                                 , @ArinvdInvSeq
                                 , @ArinvdDistSeq
                                 , @ArinvdAcct
                                 , @ArinvdAcctUnit1
                                 , @ArinvdAcctUnit2
                                 , @ArinvdAcctUnit3
                                 , @ArinvdAcctUnit4
                                 , @ArinvdAmount
                                 , 1
                                 )
                  END 
                  
               END 

             
             UPDATE co SET surcharge_t = @CoSurcharge WHERE co_num = @InvItemCoNum
         END
         SET @DistacctRowPointer = dbo.FndDist(@CoitemItem, @CoitemWhse)
         IF @DistacctRowPointer IS NOT NULL
         BEGIN
            SET @DistacctSalesAcct       = NULL
            SET @DistacctSaleDsAcct      = NULL
            SET @DistacctSalesAcctUnit1  = NULL
            SET @DistacctSalesAcctUnit2  = NULL
            SET @DistacctSalesAcctUnit3  = NULL
            SET @DistacctSalesAcctUnit4  = NULL
            SET @DistacctSaleDsAcctUnit1 = NULL
            SET @DistacctSaleDsAcctUnit2 = NULL
            SET @DistacctSaleDsAcctUnit3 = NULL
            SET @DistacctSaleDsAcctUnit4 = NULL

            SELECT
                 @DistacctSalesAcct       = distacct.sales_acct
               , @DistacctSaleDsAcct      = distacct.sale_ds_acct
               , @DistacctSalesAcctUnit1  = distacct.sales_acct_unit1
               , @DistacctSalesAcctUnit2  = distacct.sales_acct_unit2
               , @DistacctSalesAcctUnit3  = distacct.sales_acct_unit3
               , @DistacctSalesAcctUnit4  = distacct.sales_acct_unit4
               , @DistacctSaleDsAcctUnit1 = distacct.sale_ds_acct_unit1
               , @DistacctSaleDsAcctUnit2 = distacct.sale_ds_acct_unit2
               , @DistacctSaleDsAcctUnit3 = distacct.sale_ds_acct_unit3
               , @DistacctSaleDsAcctUnit4 = distacct.sale_ds_acct_unit4
            FROM distacct with (readuncommitted)
            WHERE distacct.RowPointer = @DistacctRowPointer

         END

         SET @ProdcodeRowPointer = NULL
         SET @ProdcodeUnit       = NULL
       
         IF @NonInventoryItem <> 1
          BEGIN
           SELECT
                @ProdcodeRowPointer = prodcode.RowPointer
              , @ProdcodeUnit       = prodcode.unit
           FROM prodcode with (readuncommitted)
           WHERE prodcode.product_code = @ItemProductCode
          END   

         SET @TEndSales      = NULL
         SET @TEndSalesUnit1 = NULL
         SET @TEndSalesUnit2 = NULL
         SET @TEndSalesUnit3 = NULL
         SET @TEndSalesUnit4 = NULL

         /* IF ENDYTYPE INFO NOT AVAIL FOR SALES/DISC THEN USE DIST INFO */
         
         IF @NonInventoryItem = 1
         BEGIN      
            SET @TEndSales = @CoitemNonInvAcct
            SET @TEndSalesUnit1 = @CoitemNonInvAcctUnit1
            SET @TEndSalesUnit2 = @CoitemNonInvAcctUnit2
            SET @TEndSalesUnit3 = @CoitemNonInvAcctUnit3
            SET @TEndSalesUnit4 = @CoitemNonInvAcctUnit4
            
            IF @TEndSales is NULL
            BEGIN
               SET @TEndSales = @EndTypeNonInvAcct
               SET @TEndSalesUnit1 = @EndTypeNonInvAcctUnit1
               SET @TEndSalesUnit2 = @EndTypeNonInvAcctUnit2
               SET @TEndSalesUnit3 = @EndTypeNonInvAcctUnit3
               SET @TEndSalesUnit4 = @EndTypeNonInvAcctUnit4
            END
            IF @TEndSales is NULL
            BEGIN
               SET @TEndSales = @ArparmsNonInvAcct
               SET @TEndSalesUnit1 = @ArparmsNonInvAcctUnit1
               SET @TEndSalesUnit2 = @ArparmsNonInvAcctUnit2
               SET @TEndSalesUnit3 = @ArparmsNonInvAcctUnit3
               SET @TEndSalesUnit4 = @ArparmsNonInvAcctUnit4
            END
         END
         ELSE
         BEGIN
            IF @EndtypeSalesAcct IS NOT NULL 
            BEGIN
               SET @TEndSales = @EndtypeSalesAcct
               SET @TEndSalesUnit1 = @EndtypeSalesAcctUnit1
               SET @TEndSalesUnit2 = @EndtypeSalesAcctUnit2
               SET @TEndSalesUnit3 = @EndtypeSalesAcctUnit3
               SET @TEndSalesUnit4 = @EndtypeSalesAcctUnit4
            END
            ELSE
            BEGIN
               SET @TEndSales = @DistacctSalesAcct
               SET @TEndSalesUnit1 = @DistacctSalesAcctUnit1
               SET @TEndSalesUnit2 = @DistacctSalesAcctUnit2
               SET @TEndSalesUnit3 = @DistacctSalesAcctUnit3
               SET @TEndSalesUnit4 = @DistacctSalesAcctUnit4
            END
         END

         IF @ProdcodeRowPointer IS NOT NULL AND @TEndSalesUnit2 IS NULL
            SET @TEndSalesUnit2 = dbo.ValUnit2(@TEndSales, @ProdcodeUnit, NULL)

         IF @TEndSales IS NOT NULL
         BEGIN
            SET @ArinvdRowPointer = NULL
            SET @ArinvdAmount     = 0

            SELECT TOP 1
                 @ArinvdRowPointer = RowPointer
               , @ArinvdAmount     = amount
            FROM @TmpArinvd
            WHERE cust_num = @ArinvCustNum
              AND inv_num = @ArinvInvNum
              AND inv_seq = @ArinvInvSeq
              AND acct = @TEndSales
              AND ISNULL(acct_unit1,'') = ISNULL(@TEndSalesUnit1,'')
              AND ISNULL(acct_unit2,'') = ISNULL(@TEndSalesUnit2,'')
              AND ISNULL(acct_unit3,'') = ISNULL(@TEndSalesUnit3,'')
              AND ISNULL(acct_unit4,'') = ISNULL(@TEndSalesUnit4,'')

            SET @ArinvdAmount     = ISNULL(@ArinvdAmount, 0)

            IF @ArinvdRowPointer IS NULL
            BEGIN

               --create arinvd
               -- INITIALIZING VARS FOR TABLE INSERT

               SET @TDistSeq = @TDistSeq + 5
               SET @ArinvdCustNum = @ArinvCustNum
               SET @ArinvdInvNum  = @ArinvInvNum
               SET @ArinvdInvSeq  = @ArinvInvSeq
               SET @ArinvdDistSeq = @TDistSeq
               SET @ArinvdAcct = @TEndSales
               SET @ArinvdAcctUnit1 = @TEndSalesUnit1
               SET @ArinvdAcctUnit2 = @TEndSalesUnit2
               SET @ArinvdAcctUnit3 = @TEndSalesUnit3
               SET @ArinvdAcctUnit4 = @TEndSalesUnit4

               IF  @InvCred = 'I'
                  SET @ArinvdAmount = @ArinvdAmount + @TLineTot + @AmountToApply + (CASE WHEN @TaxInclDiscount = 0
                                                                                         THEN @TotalTaxOnDiscAmount
                                                                                         ELSE 0
                                                                                    END)
               ELSE
                  SET @ArinvdAmount = @ArinvdAmount - @TLineTot - (CASE WHEN @TaxInclDiscount = 0
                                                                        THEN @TotalTaxOnDiscAmount
                                                                        ELSE 0
                                                                   END)

               SET @ArinvdAmount = ROUND(@ArinvdAmount, @CurrencyPlaces)
                                            
               SET @ArinvdRowPointer = NewId()
               If @SumProAmount > 0
                  SET @ArinvdAmount = @ArinvdAmount -@SumProAmount
               INSERT INTO @TmpArinvd(cust_num, inv_num, inv_seq, dist_seq, acct
                                , acct_unit1, acct_unit2, acct_unit3, acct_unit4, ref_type
                                , ref_num, ref_line_suf, ref_release, amount, new, RowPointer)
               VALUES (@ArinvdCustNum, @ArinvdInvNum, @ArinvdInvSeq, @ArinvdDistSeq, @ArinvdAcct
                      , @ArinvdAcctUnit1, @ArinvdAcctUnit2, @ArinvdAcctUnit3, @ArinvdAcctUnit4, @ArinvdRefType
                      , @ArinvdRefNum, @ArinvdRefLineSuf, @ArinvdRefRelease, @ArinvdAmount, 1, @ArinvdRowPointer)
            END
            ELSE
            BEGIN
               IF @InvCred = 'I'
                  SET @ArinvdAmount = @ArinvdAmount + @TLineTot + @AmountToApply + (CASE WHEN @TaxInclDiscount = 0
                                                                                         THEN @TotalTaxOnDiscAmount
                                                                                         ELSE 0
                                                                                    END)
               ELSE
                  SET @ArinvdAmount = @ArinvdAmount - @TLineTot - (CASE WHEN @TaxInclDiscount = 0
                                                                        THEN @TotalTaxOnDiscAmount
                                                                        ELSE 0
                                                                   END)
               If @SumProAmount > 0
                  SET @ArinvdAmount = @ArinvdAmount -@SumProAmount
                  
               UPDATE @TmpArinvd
               SET amount = ROUND(@ArinvdAmount, @CurrencyPlaces)
               WHERE RowPointer = @ArinvdRowPointer
            END

            IF (@CoCustShipmentApprovalRequired = 1)
               UPDATE co_ship_approval_log
               SET inv_num = @ArinvdInvNum
               , inv_seq = @ArinvdInvSeq
               WHERE co_num = @CoitemCoNum
               AND co_line = @CoitemCoLine
               AND co_release = @CoitemCoRelease
               AND inv_num is null
               AND approval_date BETWEEN IsNull(@StartLastShipDate, approval_date) AND
                                         IsNull (dbo.DayEndOf(@EndLastShipDate), approval_date)
         END /* IF @TEndSales IS NOT NULL */

         IF @TEndSales IS NOT NULL   --<> nil-acct
         BEGIN
            SET @InvItemSalesAcct = @TEndSales
            SET @InvItemSalesAcctUnit1 = @TEndSalesUnit1
            SET @InvItemSalesAcctUnit2 = @TEndSalesUnit2
            SET @InvItemSalesAcctUnit3 = @TEndSalesUnit3
            SET @InvItemSalesAcctUnit4 = @TEndSalesUnit4
         END

         /* progressive billing posting */
         IF ((@CoitemRefType = 'K' AND @ArparmsProjAcct <> '') OR
             @ArparmsProgAcct <> '') AND @AmountToApply <> 0
             and @NoProg = 0
         BEGIN

            IF @CoitemRefType = 'K' AND @ArparmsProjAcct <> ''
            BEGIN
               SET @TProgAcct      = @ArparmsProjAcct
               SET @TProgAcctUnit1 = @ArparmsProjAcctUnit1
               SET @TProgAcctUnit2 = @ArparmsProjAcctUnit2
               SET @TProgAcctUnit3 = @ArparmsProjAcctUnit3
               SET @TProgAcctUnit4 = @ArparmsProjAcctUnit4
            END
            ELSE
            BEGIN
               SET @TProgAcct      = @ArparmsProgAcct
               SET @TProgAcctUnit1 = @ArparmsProgAcctUnit1
               SET @TProgAcctUnit2 = @ArparmsProgAcctUnit2
               SET @TProgAcctUnit3 = @ArparmsProgAcctUnit3
               SET @TProgAcctUnit4 = @ArparmsProgAcctUnit4
            END

            SET @ArinvdRowPointer = NULL
            SET @ArinvdAmount     = 0

            SELECT TOP 1 /* first */
                 @ArinvdRowPointer = RowPointer
               , @ArinvdAmount     = amount
            FROM @TmpArinvd
            WHERE cust_num = @ArinvCustNum
              AND inv_num = @ArinvInvNum
              AND inv_seq = @ArinvInvSeq
              AND acct = @ArparmsProgAcct
              AND ISNULL(acct_unit1,'') = ISNULL(@TProgAcctUnit1,'')
              AND ISNULL(acct_unit2,'') = ISNULL(@TProgAcctUnit2,'')
              AND ISNULL(acct_unit3,'') = ISNULL(@TProgAcctUnit3,'')
              AND ISNULL(acct_unit4,'') = ISNULL(@TProgAcctUnit4,'')

            SET @ArinvdAmount     = ISNULL(@ArinvdAmount, 0)

            IF @ArinvdRowPointer IS NULL
            BEGIN

               --create arinvd
               -- INITIALIZING VARS FOR TABLE INSERT

               SET @TDistSeq = @TDistSeq + 5
               SET @ArinvdCustNum = @ArinvCustNum
               SET @ArinvdInvNum  = @ArinvInvNum
               SET @ArinvdInvSeq  = @ArinvInvSeq
               SET @ArinvdDistSeq = @TDistSeq
               SET @ArinvdAcct     = @TProgAcct
               SET @ArinvdAcctUnit1 = @TProgAcctUnit1
               SET @ArinvdAcctUnit2 = @TProgAcctUnit2
               SET @ArinvdAcctUnit3 = @TProgAcctUnit3
               SET @ArinvdAcctUnit4 = @TProgAcctUnit4

               IF  @InvCred = 'I'
                  SET @ArinvdAmount = @ArinvdAmount - @AmountToApply

               SET @ArinvdAmount = ROUND(@ArinvdAmount, @CurrencyPlaces) + @ProgressiveRoundingAmt

               SET @ArinvdRowPointer = NewId()       
               INSERT INTO @TmpArinvd
                  (cust_num, inv_num, inv_seq, dist_seq, acct
                 , acct_unit1, acct_unit2, acct_unit3, acct_unit4, ref_type
                 , ref_num, ref_line_suf, ref_release, amount, new, RowPointer)
               VALUES
                  (@ArinvdCustNum, @ArinvdInvNum, @ArinvdInvSeq, @ArinvdDistSeq, @ArinvdAcct
                 , @ArinvdAcctUnit1, @ArinvdAcctUnit2, @ArinvdAcctUnit3, @ArinvdAcctUnit4, @ArinvdRefType
                 , @ArinvdRefNum, @ArinvdRefLineSuf, @ArinvdRefRelease, @ArinvdAmount, 1, @ArinvdRowPointer)
            END
            ELSE
            BEGIN
               IF  @InvCred = 'I'
               BEGIN
                  SET @ArinvdAmount = @ArinvdAmount - @AmountToApply

                  UPDATE @TmpArinvd
                  SET amount = ROUND(@ArinvdAmount, @CurrencyPlaces)
                  WHERE RowPointer = @ArinvdRowPointer
               END
            END

            IF (@CoCustShipmentApprovalRequired = 1)
               UPDATE co_ship_approval_log
               SET inv_num = @ArinvdInvNum
               , inv_seq = @ArinvdInvSeq
               WHERE co_num = @CoitemCoNum
               AND co_line = @CoitemCoLine
               AND co_release = @CoitemCoRelease
               AND inv_num is null
               AND approval_date BETWEEN IsNull(@StartLastShipDate, approval_date) AND
                                         IsNull (dbo.DayEndOf(@EndLastShipDate), approval_date)
         END /* IF ((@CoitemRefType = 'K' AND @ArparmsProjAcct <> '') OR ... */

         /* POST SALES DISCOUNT IF AVAILABLE SALES DISCOUNT ACCOUNT */

         IF @EndtypeSalesDsAcct IS NULL
         BEGIN
            SET @TEndDisc = @DistacctSaleDsAcct
            SET @TEndDiscUnit1 = @DistacctSaleDsAcctUnit1
            SET @TEndDiscUnit2 = @DistacctSaleDsAcctUnit2
            SET @TEndDiscUnit3 = @DistacctSaleDsAcctUnit3
            SET @TEndDiscUnit4 = @DistacctSaleDsAcctUnit4
         END
         ELSE
         BEGIN
            SET @TEndDisc      = @EndtypeSalesDsAcct
            SET @TEndDiscUnit1 = @EndtypeSalesDsAcctUnit1
            SET @TEndDiscUnit2 = @EndtypeSalesDsAcctUnit2
            SET @TEndDiscUnit3 = @EndtypeSalesDsAcctUnit3
            SET @TEndDiscUnit4 = @EndtypeSalesDsAcctUnit4
         END

         IF @TEndDisc IS NULL
         BEGIN
            SET @TEndDisc      = @ArparmsSalesDiscAcct
            SET @TEndDiscUnit1 = @ArparmsSalesDiscAcctUnit1
            SET @TEndDiscUnit2 = @ArparmsSalesDiscAcctUnit2
            SET @TEndDiscUnit3 = @ArparmsSalesDiscAcctUnit3
            SET @TEndDiscUnit4 = @ArparmsSalesDiscAcctUnit4
         END

         IF @ProdcodeRowPointer IS NOT NULL and @TEndDiscUnit2 is null
            SET @TEndDiscUnit2 = dbo.ValUnit2(@TEndDisc, @ProdcodeUnit, NULL)

         IF @TEndDisc IS NOT NULL and @CoitemDisc <> 0.0
         BEGIN
            SET @ArinvdRowPointer = NULL
            SET @ArinvdAmount     = 0

            SELECT TOP 1 /* first */
                 @ArinvdRowPointer = RowPointer
               , @ArinvdAmount     = amount
            FROM @TmpArinvd
            WHERE cust_num = @ArinvCustNum
              AND inv_num = @ArinvInvNum
              AND inv_seq = @ArinvInvSeq
              AND acct = @TEndDisc
              AND ISNULL(acct_unit1,'') = ISNULL(@TEndDiscUnit1,'')
              AND ISNULL(acct_unit2,'') = ISNULL(@TEndDiscUnit2,'')
              AND ISNULL(acct_unit3,'') = ISNULL(@TEndDiscUnit3,'')
              AND ISNULL(acct_unit4,'') = ISNULL(@TEndDiscUnit4,'')


            SET @ArinvdAmount     = ISNULL(@ArinvdAmount, 0)

            IF @ArinvdRowPointer IS NULL
            BEGIN

               --create arinvd
               -- INITIALIZING VARS FOR TABLE INSERT
               SET @TDistSeq = @TDistSeq + 5
               SET @ArinvdCustNum = @ArinvCustNum
               SET @ArinvdInvNum  = @ArinvInvNum
               SET @ArinvdInvSeq  = @ArinvInvSeq
               SET @ArinvdDistSeq = @TDistSeq
               SET @ArinvdAcct     = @TEndDisc
               SET @ArinvdAcctUnit1 = @TEndDiscUnit1
               SET @ArinvdAcctUnit2 = @TEndDiscUnit2
               SET @ArinvdAcctUnit3 = @TEndDiscUnit3
               SET @ArinvdAcctUnit4 = @TEndDiscUnit4

               IF  @InvCred = 'I'
                  SET @ArinvdAmount = @ArinvdAmount - (CASE WHEN @CoIncludeTaxInPrice = 0
                                                            THEN (@TLineTot - @TLineNet)
                                                            ELSE @DiscAmountInclTax
                                                       END)
               ELSE
                  SET @ArinvdAmount = @ArinvdAmount + (CASE WHEN @CoIncludeTaxInPrice = 0
                                                            THEN (@TLineTot - @TLineNet)
                                                            ELSE @DiscAmountInclTax
                                                       END)

               SET @ArinvdAmount = ROUND(@ArinvdAmount, @CurrencyPlaces)             
               
               SET @ArinvdRowPointer = NewId()     
               INSERT INTO @TmpArinvd
                      (cust_num, inv_num, inv_seq, dist_seq, acct
                     , acct_unit1, acct_unit2, acct_unit3, acct_unit4, ref_type
                     , ref_num, ref_line_suf, ref_release, amount, new, RowPointer)
               VALUES (@ArinvdCustNum, @ArinvdInvNum, @ArinvdInvSeq, @ArinvdDistSeq, @ArinvdAcct
                     , @ArinvdAcctUnit1, @ArinvdAcctUnit2, @ArinvdAcctUnit3, @ArinvdAcctUnit4, @ArinvdRefType
                     , @ArinvdRefNum, @ArinvdRefLineSuf, @ArinvdRefRelease, @ArinvdAmount, 1, @ArinvdRowPointer)

            END
            ELSE
            BEGIN
               IF @InvCred = 'I'
                  SET @ArinvdAmount = @ArinvdAmount - (CASE WHEN @CoIncludeTaxInPrice = 0
                                                            THEN (@TLineTot - @TLineNet)
                                                            ELSE @DiscAmountInclTax
                                                       END)
               ELSE
                  SET @ArinvdAmount = @ArinvdAmount + (CASE WHEN @CoIncludeTaxInPrice = 0
                                                            THEN (@TLineTot - @TLineNet)
                                                            ELSE @DiscAmountInclTax
                                                       END)
               UPDATE @TmpArinvd
               SET amount = ROUND(@ArinvdAmount, @CurrencyPlaces)
               WHERE RowPointer = @ArinvdRowPointer
            END
               
            IF (@CoCustShipmentApprovalRequired = 1)
               UPDATE co_ship_approval_log
               SET inv_num = @ArinvdInvNum
               , inv_seq = @ArinvdInvSeq
               WHERE co_num = @CoitemCoNum
               AND co_line = @CoitemCoLine
               AND co_release = @CoitemCoRelease
               AND inv_num is null
               AND approval_date BETWEEN IsNull(@StartLastShipDate, approval_date) AND
                                         IsNull (dbo.DayEndOf(@EndLastShipDate), approval_date)  
         END  /* IF @TEndDisc IS NOT NULL and @CoitemDisc <> 0.0 */

         IF @TEndDisc IS NULL
         BEGIN

            SET @Infobar = NULL
            EXEC @Severity = dbo.MsgAppSp @Infobar OUTPUT, 'E=NoExistFor1'
               , '@distacct.sale_ds_acct'
               , '@item'
               , '@item.product_code'
               , @ItemProductCode

            -- ???
            -- EXEC @Severity = dbo.MsgAppSp @Infobar OUTPUT, 'Q=CmdContinueNoYes'
            -- , '@%post'

            GOTO EXIT_SP
         END

         /* POST TO INVOICE HISTORY & EC SSD REPORT DATA (same file) */
         
         SET @SSSVTXInvItemRowPointer = NEWID()  
         
         --create inv_item
         INSERT INTO #TmpInvItem
                   ( inv_num, inv_seq, inv_line, co_num,
                     co_line, co_release, item, disc,
                     price, process_ind, cons_num, tax_code1,
                     tax_code2, tax_date, cust_po, qty_invoiced,
                     cost, sales_acct, sales_acct_unit1, sales_acct_unit2,
                     sales_acct_unit3, sales_acct_unit4, orig_inv_num, reason_text, 
                     excise_tax_percent, rowpointer )
         VALUES (  @InvItemInvNum, @InvItemInvSeq, @InvItemInvLine, @InvItemCoNum,
                      @InvItemCoLine, @InvItemCoRelease, @InvItemItem, @InvItemDisc,
                      @InvItemPrice, @InvItemProcessInd, @InvItemConsNum, @InvItemTaxCode1,
                      @InvItemTaxCode2, @InvItemTaxDate, @InvItemCustPo, @InvItemQtyInvoiced,
                      @InvItemCost, @InvItemSalesAcct, @InvItemSalesAcctUnit1, @InvItemSalesAcctUnit2,
                      @InvItemSalesAcctUnit3, @InvItemSalesAcctUnit4, @InvItemOrigInvoice, @InvItemReasonText, 
                      @InvItemExciseTaxPercent, @SSSVTXInvItemRowPointer  )

         IF EXISTS (SELECT 1 FROM taxcode with (readuncommitted)
                             WHERE tax_code_type = 'R' 
                             AND tax_surcharge = 1
                             AND tax_code = ISNULL(@InvItemTaxCode1,@CoTaxCode1))
         BEGIN
            SET @OLvlDiscLineNet = @OLvlDiscLineNet + @LineSurcharge
         END
		 
         SET @LineMethodRefType = CASE When @UseJPLineMethod = 1 THEN 'L' ELSE 'I' END

         EXEC @Severity = dbo.TaxBaseSp
            'R',                   /* p-inv-type = Regular */
            @LineMethodRefType,    /* F Freight, M Misc chgs, I Line Items, L = LineMethod */
            @InvItemTaxCode1,      /* p-tax-code1 */
            @InvItemTaxCode2,      /* p-tax-code2 */
            @OLvlDiscLineNet,      /* p-amount */
            @TaxBaseAmountToApply, /* p-amount-to-apply */
            @TaxBaseTLineTot,      /* p-undisc-amount */
            @ItemUWsPrice,         /* p-u-ws-price */
            @TTaxablePrice,        /* p-taxable-price, */
            @InvItemQtyInvoiced,
            @CustaddrCurrCode,     /* p-curr-code */
            @InvHdrInvDate,        /* p-inv-date, ? = use today */
            @InvHdrExchRate,       /* p-exch-rate, ? = lookup */
            @InfoBar      OUTPUT
          , @pRefType       = 'I'                           
          , @pHdrPtr        = @InvHdrRowPointer             
          , @pLineRefType   = null                          
          , @pLinePtr       = @SSSVTXInvItemRowPointer      
      
         IF @Severity <> 0
             GOTO EXIT_SP             
         
         SET @TBalAdj = 0

         SET @InvHdrCost = @InvHdrCost + (@InvItemCost * @InvItemQtyInvoiced)
         SET @InvHdrShipDate = CASE WHEN @InvHdrShipDate < @CoitemShipDate
                                    THEN @InvHdrShipDate
                                    ELSE @CoitemShipDate
                               END

         UPDATE #TmpInvHdr
            SET cost = @InvHdrCost
              , ship_date = @InvHdrShipDate
         WHERE RowPointer = @InvHdrRowPointer

         SET @TSubTotal = @TSubTotal + CASE WHEN @CoIncludeTaxInPrice = 0
                                            THEN @TLineNet
                                            ELSE ( @OLvlDiscLineNet - (CASE WHEN @TaxInclDiscount = 0
                                                                            THEN 0
                                                                            ELSE @TotalTaxOnDiscAmount
                                                                       END) )
                                       END

         SET @TBalAdj = 
                  (CASE WHEN @CoParmsUseAltPriceCalc = 1 THEN
                         round( (round(@CoitemPrice * (1 - @CoitemDisc / 100), @CurrencyPlaces) * @TCoitemQty), @CurrencyPlaces)
                         - (@CoitemPrgBillTot - @CoitemPrgBillApp)
                   ELSE
                         round(@TCoitemQty * @CoitemPrice * (1 - @CoitemDisc / 100), @CurrencyPlaces)
                        - (@CoitemPrgBillTot - @CoitemPrgBillApp)
                   END)

         SET @BalAdj = @BalAdj + @TBalAdj

         update @TmpCoitem
         set ship_date = dbo.MaxDate(ship_date, @CoitemShipDate)
         , prg_bill_app = @CoitemPrgBillApp
         , qty_invoiced = @CoitemQtyInvoiced
         , qty_returned = @CoitemQtyReturned
         where RowPointer = @CoitemRowPointer
         if @@rowcount = 0
            INSERT INTO @TmpCoitem (
              ship_date
            , prg_bill_app
            , qty_invoiced
            , qty_returned
            , RowPointer)
            SELECT
              @CoitemShipDate
            , @CoitemPrgBillApp
            , @CoitemQtyInvoiced
            , @CoitemQtyReturned
            , @CoitemRowPointer

         IF @LinesPerDoc > 0 AND @RowNum = @LinesPerDoc
            BREAK
      END
      CLOSE      coitem_Crs
      DEALLOCATE coitem_Crs /* for each coitem */

      IF @EndtypeSalesDsAcct IS NULL
      BEGIN
         SET @TEndDisc      = @ArparmsSalesDiscAcct
         SET @TEndDiscUnit1 = @ArparmsSalesDiscAcctUnit1
         SET @TEndDiscUnit2 = @ArparmsSalesDiscAcctUnit2
         SET @TEndDiscUnit3 = @ArparmsSalesDiscAcctUnit3
         SET @TEndDiscUnit4 = @ArparmsSalesDiscAcctUnit4
      END
      ELSE
      BEGIN
         SET @TEndDisc      = @EndtypeSalesDsAcct
         SET @TEndDiscUnit1 = @EndtypeSalesDsAcctUnit1
         SET @TEndDiscUnit2 = @EndtypeSalesDsAcctUnit2
         SET @TEndDiscUnit3 = @EndtypeSalesDsAcctUnit3
         SET @TEndDiscUnit4 = @EndtypeSalesDsAcctUnit4
      END

      IF  @InvCred = 'I'
      BEGIN
         SET @InvHdrMiscCharges = @CoMiscCharges
         SET @InvHdrFreight      = @CoFreight
      END
      ELSE
      BEGIN
         SET @InvHdrMiscCharges = -(@CoMiscCharges)
         SET @InvHdrFreight      = -(@CoFreight)
      END

      SET @TSalesTax     = 0
      SET @TSalesTax2    = 0

      /* COMPUTE TAX & TOTAL */      
      EXEC @Severity = dbo.TaxCalcSp
         'R',                       /* p-inv-type = Regular */
         @InvHdrTaxCode1,           /* p-tax-code1       */
         @InvHdrTaxCode2,           /* p-tax-code2       */
         @InvHdrFreight,            /* p-freight         */
         @InvHdrFrtTaxCode1,        /* p-frt-tax-code1   */
         @InvHdrFrtTaxCode2,        /* p-frt-tax-code2   */
         @InvHdrMiscCharges,        /* p-misc            */
         @InvHdrMscTaxCode1,        /* p-frt-tax-code1   */
         @InvHdrMscTaxCode2,        /* p-frt-tax-code2   */
         @InvHdrInvDate,            /* p-inv-date        */
         @InvHdrTermsCode,          /* p-terms-code      */
         @InvHdrUseExchRate,
         @CustaddrCurrCode,
         @CurrencyPlaces,           /* p-places    */
         @InvHdrExchRate,           /* p-exch-rate */
         @TSalesTax     OUTPUT,
         @TSalesTax2    OUTPUT,
         @Infobar       OUTPUT,
         @pRefType       = 'I',                     
         @pHdrPtr        = @InvHdrRowPointer   


      IF @Severity <> 0
      BEGIN
         EXEC @Severity = dbo.MsgAppSp @Infobar OUTPUT, 'E=CmdFailed1'
            , '@%co/tax-calc'
            , '@co'
            , '@co.co_num'
            , @CoCoNum

         GOTO EXIT_SP
      END

      if @CoIncludeTaxInPrice = 1
      begin
         -- fudge total tax to match the sum of the detail if it looks like a minor rounding difference
         set @TaxDiff = @AccumTax1 - @TSalesTax
         if @TaxDiff != 0
         and abs(@TaxDiff) <= (@RowNum / 0.02)
         begin
            declare taxadjCrs cursor local static for
            select RowPointer
            from tmp_tax_calc
            where ProcessId = @SessionId
            and tax_amt != 0
            and tax_system = 1

            open taxadjCrs
            while @TaxDiff != 0
            begin
               fetch taxadjCrs into
                 @TmpTaxCalcRowPointer
               if @@fetch_status != 0
                  break

               update tmp_tax_calc
               set tax_amt = tax_amt + case when @TaxDiff > 0 then 0.01 else -0.01 end
               where ProcessId = @SessionId
               and RowPointer = @TmpTaxCalcRowPointer

               set @TSalesTax = @TSalesTax + case when @TaxDiff > 0 then 0.01 else -0.01 end
               set @TaxDiff = @TaxDiff - case when @TaxDiff > 0 then 0.01 else -0.01 end
            end
            close taxadjCrs
            deallocate taxadjCrs
         end

         set @TaxDiff = @AccumTax2 - @TSalesTax2
         if @TaxDiff != 0
         and abs(@TaxDiff) <= (@RowNum / 0.02)
         begin
            declare taxadjCrs cursor local static for
            select RowPointer
            from tmp_tax_calc
            where ProcessId = @SessionId
            and tax_amt != 0
            and tax_system = 2

            open taxadjCrs
            while @TaxDiff != 0
            begin
               fetch taxadjCrs into
                 @TmpTaxCalcRowPointer
               if @@fetch_status != 0
                  break

               update tmp_tax_calc
               set tax_amt = tax_amt + case when @TaxDiff > 0 then 0.01 else -0.01 end
               where ProcessId = @SessionId
               and RowPointer = @TmpTaxCalcRowPointer

               set @TSalesTax2 = @TSalesTax2 + case when @TaxDiff > 0 then 0.01 else -0.01 end
               set @TaxDiff = @TaxDiff - case when @TaxDiff > 0 then 0.01 else -0.01 end
            end
            close taxadjCrs
            deallocate taxadjCrs
         end
      end

      /* CREATE inv-stax RECORDS */
      Set @TTaxSeq = 0

      --Leave the following comments in case needed for future debugging
      --SELECT @Count = COUNT(*) FROM tmp_tax_calc
      --SET @TraceMsg = 'InvPostSp: Before cursor - TaxCalc Count=' + CONVERT(NVARCHAR(20), @Count)
      --EXEC SLDevEnv_App.dbo.SQLTraceSp @TraceMsg, 'thoblo'
------------

     IF @UseJPLineMethod = 1 
       INSERT INTO @inv_stax (
              inv_num
            , inv_seq
            , seq
            , tax_code
            , sales_tax
            , stax_acct
            , stax_acct_unit1
            , stax_acct_unit2
            , stax_acct_unit3
            , stax_acct_unit4
            , inv_date
            , cust_num
            , cust_seq
            , tax_basis
            , tax_system
            , tax_rate
            , tax_jur
            , tax_code_e  )
         SELECT
              @InvHdrInvNum
            , @InvHdrInvSeq
            , @TTaxSeq
            , w_tax_calc.tax_code
            , SUM(round(isnull(w_tax_calc.tax_amt, 0), @CurrencyPlaces))
            , w_tax_calc.ar_acct
            , w_tax_calc.ar_acct_unit1
            , w_tax_calc.ar_acct_unit2
            , w_tax_calc.ar_acct_unit3
            , w_tax_calc.ar_acct_unit4
            , @InvHdrTaxDate
            , @InvHdrCustNum
            , @InvHdrCustSeq
            -- when the amount to be rounded is .5, round down instead of up
            -- because discounts will cause the CO amount to be rounded up, so
            -- this complimentary amount needs to be rounded down.
            , SUM(case when abs(isnull(w_tax_calc.tax_basis, 0) - round(isnull(w_tax_calc.tax_basis, 0), @CurrencyPlaces)) = 5.0 / power(10, @CurrencyPlaces + 1)
                   then isnull(w_tax_calc.tax_basis, 0) - 5.0 / power(10, @CurrencyPlaces + 1)
                   else round(isnull(w_tax_calc.tax_basis, 0), @CurrencyPlaces)
                   end)
            , w_tax_calc.tax_system
            , isnull(w_tax_calc.tax_rate, 0)
            , w_tax_calc.tax_jur
            , w_tax_calc.tax_code_e
        FROM  tmp_tax_calc AS w_tax_calc
        WHERE w_tax_calc.ProcessId = @SessionId
          AND (isnull(w_tax_calc.record_zero, 0) <> 0 or isnull(w_tax_calc.tax_amt, 0) <> 0)
        GROUP BY tax_code, tax_system, ar_acct, ar_acct_unit1, ar_acct_unit2, ar_acct_unit3, ar_acct_unit4, tax_rate, tax_jur, tax_code_e

     ELSE
       INSERT INTO @inv_stax (
              inv_num
            , inv_seq
            , seq
            , tax_code
            , sales_tax
            , stax_acct
            , stax_acct_unit1
            , stax_acct_unit2
            , stax_acct_unit3
            , stax_acct_unit4
            , inv_date
            , cust_num
            , cust_seq
            , tax_basis
            , tax_system
            , tax_rate
            , tax_jur
            , tax_code_e  )
         SELECT
              @InvHdrInvNum
            , @InvHdrInvSeq
            , @TTaxSeq
            , w_tax_calc.tax_code
            , round(isnull(w_tax_calc.tax_amt, 0), @CurrencyPlaces)
            , w_tax_calc.ar_acct
            , w_tax_calc.ar_acct_unit1
            , w_tax_calc.ar_acct_unit2
            , w_tax_calc.ar_acct_unit3
            , w_tax_calc.ar_acct_unit4
            , @InvHdrTaxDate
            , @InvHdrCustNum
            , @InvHdrCustSeq
            -- when the amount to be rounded is .5, round down instead of up
            -- because discounts will cause the CO amount to be rounded up, so
            -- this complimentary amount needs to be rounded down.
            , case when abs(isnull(w_tax_calc.tax_basis, 0) - round(isnull(w_tax_calc.tax_basis, 0), @CurrencyPlaces)) = 5.0 / power(10, @CurrencyPlaces + 1)
               then isnull(w_tax_calc.tax_basis, 0) - 5.0 / power(10, @CurrencyPlaces + 1)
               else round(isnull(w_tax_calc.tax_basis, 0), @CurrencyPlaces)
               end
            , w_tax_calc.tax_system
            , isnull(w_tax_calc.tax_rate, 0)
            , w_tax_calc.tax_jur
            , w_tax_calc.tax_code_e
        FROM  tmp_tax_calc AS w_tax_calc
        WHERE w_tax_calc.ProcessId = @SessionId
          AND (isnull(w_tax_calc.record_zero, 0) <> 0 or isnull(w_tax_calc.tax_amt, 0) <> 0)


     UPDATE @inv_stax
       SET seq = @TTaxSeq ,
           @TTaxSeq = @TTaxSeq + 1

    INSERT INTO @TmpInvStax (
              inv_num
            , inv_seq
            , seq
            , tax_code
            , sales_tax
            , stax_acct
            , stax_acct_unit1
            , stax_acct_unit2
            , stax_acct_unit3
            , stax_acct_unit4
            , inv_date
            , cust_num
            , cust_seq
            , tax_basis
            , tax_system
            , tax_rate
            , tax_jur
            , tax_code_e
         )
      SELECT
              inv_num
            , inv_seq
            , seq
            , tax_code
            , sales_tax
            , stax_acct
            , stax_acct_unit1
            , stax_acct_unit2
            , stax_acct_unit3
            , stax_acct_unit4
            , inv_date
            , cust_num
            , cust_seq
            , tax_basis
            , tax_system
            , tax_rate
            , tax_jur
            , tax_code_e
     FROM @inv_stax

     DELETE FROM @inv_stax

      SET @InvStaxInvNum        = @InvHdrInvNum
      SET @InvStaxInvSeq        = @InvHdrInvSeq
      SET @InvStaxSeq           = @TTaxSeq
      SET @InvStaxInvDate       = @InvHdrTaxDate
      SET @InvStaxCustNum       = @InvHdrCustNum
      SET @InvStaxCustSeq       = @InvHdrCustSeq

     SELECT
          @InvStaxTaxCode       = w_tax_calc.tax_code
        , @InvStaxSalesTax      =  isnull(w_tax_calc.tax_amt, 0)
        , @InvStaxStaxAcct      = w_tax_calc.ar_acct
        , @InvStaxStaxAcctUnit1 = w_tax_calc.ar_acct_unit1
        , @InvStaxStaxAcctUnit2 = w_tax_calc.ar_acct_unit2
        , @InvStaxStaxAcctUnit3 = w_tax_calc.ar_acct_unit3
        , @InvStaxStaxAcctUnit4 = w_tax_calc.ar_acct_unit4
        , @InvStaxTaxBasis      = isnull(w_tax_calc.tax_basis, 0)
        , @InvStaxTaxSystem     = w_tax_calc.tax_system
        , @InvStaxTaxRate       = isnull(w_tax_calc.tax_rate, 0)
        , @InvStaxTaxJur        = w_tax_calc.tax_jur
        , @InvStaxTaxCodeE      = w_tax_calc.tax_code_e
      FROM  tmp_tax_calc AS w_tax_calc
      WHERE w_tax_calc.ProcessId = @SessionId
        AND (isnull(w_tax_calc.record_zero, 0) <> 0 or isnull(w_tax_calc.tax_amt, 0) <> 0)

      SET @TDiscAmount = CASE WHEN @CoDiscountType = 'P'
                              THEN ROUND(@TSubTotFull * @InvHdrDisc / 100, @CurrencyPlaces)
                    WHEN (@CoDiscountType <> 'P' AND (ISNULL(@CoAmount,0) <> 0 OR ISNULL(@CoDiscAmount,0) <> 0))
               THEN ROUND((@TSubTotFull /(@CoAmount + @CoDiscAmount)) * @CoDiscAmount, @CurrencyPlaces)
               ELSE
               ROUND(@TSubTotFull , @CurrencyPlaces)
                         END

      IF @CoIncludeTaxInPrice = 1
         SET @TSubTotal = @TSubTotal
      ELSE
         SET @TSubTotal = @TSubTotal - @TDiscAmount

      SET @InvHdrPrice = @TSubTotal
                       + @InvHdrMiscCharges + @InvHdrFreight
                       + @TSalesTax + @TSalesTax2

      IF  @InvCred = 'I'
         SET @InvHdrPrepaidAmt  =
            CASE WHEN @CoPrepaidAmt > @InvHdrPrice AND @CoPrepaidAmt > 0
                 THEN @InvHdrPrice
                 ELSE @CoPrepaidAmt
            END
      ELSE
         SET @InvHdrPrepaidAmt  = 0

      SET @InvHdrPrice = @InvHdrPrice - @InvHdrPrepaidAmt

      /* (NEW ZEALAND) CASH SALES ROUNDING DOWN  */
      IF @TaxparmsCashRound > 0
      BEGIN
         SET @TermsRowPointer = NULL
         SET @TermsDueDays    = 0
         SET @TermsProxCode   = NULL
         SET @TermsProxDay    = 0
         SET @TermsCashOnly   = 0

         SELECT
              @TermsRowPointer = terms.RowPointer
            , @TermsDueDays    = terms.due_days
            , @TermsProxCode   = terms.prox_code
            , @TermsProxDay    = terms.prox_day
            , @TermsCashOnly   = terms.cash_only
            , @TermsDiscDays   = terms.disc_days
            , @TermsProxMonthToForward     = terms.prox_month_to_forward
            , @TermsProxDiscDay            = terms.prox_disc_day
            , @TermsProxDiscMonthToForward = terms.prox_disc_month_to_forward
            , @TermsCutoffDay              = terms.cutoff_day
            , @TermsHolidayOffsetMethod    = terms.holiday_offset_method
         FROM terms with (readuncommitted)
         WHERE terms.terms_code = @CoTermsCode

         IF (@TermsRowPointer IS NOT NULL AND @TermsCashOnly = 1)
         BEGIN
            SET @TAdjPrice = round(@InvHdrPrice / @TaxparmsCashRound, 0, 1) * @TaxparmsCashRound
            IF @TAdjPrice <> @InvHdrPrice
            BEGIN
               SET @TAdjPrice   = @TAdjPrice - @InvHdrPrice
               SET @InvHdrPrice = @InvHdrPrice + @TAdjPrice
               SET @TSubTotal   = @TSubTotal   + @TAdjPrice

               /* Adjust 1st distribution, will be sales unless missing acct */

               SET @ArinvdRowPointer = NULL
               SET @ArinvdAmount     = 0
               SET @ArinvdTaxBasis   = NULL

               SELECT top 1
                    @ArinvdRowPointer = arinvd.RowPointer
                  , @ArinvdAmount     = arinvd.amount
                  , @ArinvdTaxBasis   = arinvd.tax_basis
               FROM arinvd WITH (UPDLOCK)
               WHERE arinvd.cust_num = @ArinvCustNum
                 AND arinvd.inv_num = @ArinvInvNum
                 AND arinvd.inv_seq = @ArinvInvSeq

               SET @ArinvdAmount = ISNULL(@ArinvdAmount, 0)
               SET @ArinvdTaxBasis = ISNULL(@ArinvdTaxBasis, 0)

               IF @ArinvdRowPointer IS NOT NULL
               BEGIN
                  SET @ArinvdAmount = @ArinvdAmount +
                     CASE WHEN  @InvCred = 'I'
                          THEN @TAdjPrice
                          ELSE -@TAdjPrice
                     END

                  INSERT INTO @TmpArinvd (
                       amount
                     , new
                     , RowPointer
                     )
                  SELECT
                       @ArinvdAmount
                     , 0
                     , @ArinvdRowPointer
               END /* IF @ArinvdRowPointer IS NOT NULL */
            END /* IF @TAdjPrice <> @InvHdrPrice */
         END /* IF (@TermsRowPointer IS NOT NULL AND @TermsCashOnly = 1) */
      END /* IF @TaxparmsCashRound > 0 */

      /* SET EC-CODE OF 'BILL-TO' CUSTOMER */
      IF @ParmsEcReporting = 1
      BEGIN
         IF @ParmsCountry <> @CustaddrCountry
         BEGIN  /* Export? */
            SET @CountryRowPointer = NULL
            SET @CountryEcCode     = NULL

            SELECT
                 @CountryRowPointer = country.RowPointer
               , @CountryEcCode     = country.ec_code
            FROM country with (readuncommitted)
            WHERE country.country = @CustaddrCountry

            SET @InvHdrEcCode =
               CASE WHEN (@CountryRowPointer IS NOT NULL and @XCountryRowPointer IS NULL)
                      OR (@CountryRowPointer IS NOT NULL and @XCountryRowPointer IS NOT NULL
                          AND ISNULL(@CountryEcCode,'') <> ISNULL(@XCountryEcCode,''))
                    THEN @CountryEcCode
                    ELSE NULL
               END

            UPDATE #TmpInvHdr
               SET ec_code = @InvHdrEcCode
            WHERE RowPointer = @InvHdrRowPointer
         END /* IF @ParmsCountry <> @CustaddrCountry */
      END /* IF @ParmsEcReporting = 1 */

      /* POST TOTALS TO A/R - NOTE: SIGNS ALWAYS + IN ARINV */
      IF  @InvCred = 'C'
      BEGIN
         SET @TSubTotal      = - @TSubTotal
         SET @ArinvSalesTax  = - @TSalesTax
         SET @ArinvSalesTax2 = - @TSalesTax2
      END
      ELSE
      BEGIN
         SET @ArinvSalesTax   = @TSalesTax
         SET @ArinvSalesTax2 = @TSalesTax2
      END

      SET @ArinvMiscCharges = @CoMiscCharges
      SET @ArinvFreight     = @CoFreight
      SET @ArinvAmount      = @TSubTotal

      UPDATE @TmpArinv
         SET  sales_tax = ROUND(@ArinvSalesTax, @CurrencyPlaces)
            , sales_tax_2 = ROUND(@ArinvSalesTax2, @CurrencyPlaces)
            , misc_charges = ROUND(@ArinvMiscCharges, @CurrencyPlaces)
            , freight = ROUND(@ArinvFreight, @CurrencyPlaces)
            , amount = ROUND(@ArinvAmount, @CurrencyPlaces)
      WHERE RowPointer = @ArinvRowPointer

      SET @BalAdj = @BalAdj + @CoMiscCharges + @CoFreight + @TSubTotal + @TSalesTax + @TSalesTax2

      IF @InvCred = 'I' AND @pMooreForms = 'D' AND
         @CustomerPayType = 'D' AND @CustomerDraftPrintFlag = 1
      BEGIN
         SET @BankAddrRowPointer = NULL
         SET @BankAddrBankNumber = NULL
         SET @BankAddrAddr##1    = NULL
         SET @BankAddrAddr##2    = NULL
         SET @BankAddrBranchCode = NULL

         SELECT
              @BankAddrRowPointer = bank_addr.RowPointer
            , @BankAddrBankNumber = bank_addr.bank_number
            , @BankAddrAddr##1    = bank_addr.addr##1
            , @BankAddrAddr##2    = bank_addr.addr##2
            , @BankAddrBranchCode = bank_addr.branch_code
         FROM bank_addr with (readuncommitted)
         WHERE bank_addr.bank_code = @CustomerCustBank

         IF (@BankAddrRowPointer IS NULL)
         BEGIN
            SET @Infobar = NULL
            EXEC @Severity = dbo.MsgAppSp @Infobar OUTPUT, 'E=NoExistForIs1'
               , '@bank_addr'
               , '@bank_addr.bank_code'
               , @CustomerCustBank
               , '@customer'
               , '@customer.cust_num'
               , @CustomerCustNum

            GOTO EXIT_SP
         END

         SET @CustdrftRowPointer = Newid()
         --CREATE custdrft
         INSERT INTO @TmpCustdrft (
              cust_num
            , inv_date
            , payment_due_date
            , amount
            , exch_rate
            , stat
            , inv_num
            , co_num
            , bank_code
            , cust_bank
            , bank_number
            , bank_addr##1
            , bank_addr##2
            , branch_code
            , print_flag
            , escalation_cntr
            , RowPointer)
         VALUES(
              @ArinvCustNum
            , @ArinvInvDate
            , @ArinvDueDate
            , @ArinvAmount + @ArinvFreight + @ArinvMiscCharges + @ArinvSalesTax + @ArinvSalesTax2
            , @ArinvExchRate
            , 'T'
            , @ArinvInvNum
            , @ArinvCoNum
            , @CustomerBankCode
            , @CustomerCustBank
            , @BankAddrBankNumber
            , @BankAddrAddr##1
            , @BankAddrAddr##2
            , @BankAddrBranchCode
            , 1
            , 0
            , @CustdrftRowPointer
            )
      END

      /* POST ORDER LEVEL SALES DISCOUNT IF AVAILABLE SALES DISCOUNT ACCOUNT */
      IF @TEndDisc IS NOT NULL AND @InvHdrDisc <> 0.0
      BEGIN
         SET @ArinvdRowPointer = NULL
         SET @ArinvdAmount     = 0

         SELECT top 1 /* first */
              @ArinvdRowPointer = RowPointer
            , @ArinvdAmount     = amount
         FROM @TmpArinvd
         WHERE cust_num = @ArinvCustNum
           AND inv_num = @ArinvInvNum
           AND inv_seq = @ArinvInvSeq
           AND acct = @TEndDisc
           AND ISNULL(acct_unit1,'') = ISNULL(@TEndDiscUnit1,'')
           AND ISNULL(acct_unit2,'') = ISNULL(@TEndDiscUnit2,'')
           AND ISNULL(acct_unit3,'') = ISNULL(@TEndDiscUnit3,'')
           AND ISNULL(acct_unit4,'') = ISNULL(@TEndDiscUnit4,'')

         SET @ArinvdAmount    = ISNULL(@ArinvdAmount, 0)
         SET @ArinvdTaxBasis  = ISNULL(@ArinvdTaxBasis, 0)

         IF @ArinvdRowPointer IS NULL
         BEGIN
            --create arinvd

            SET @TDistSeq = @TDistSeq + 5
            SET @ArinvdCustNum = @ArinvCustNum
            SET @ArinvdInvNum = @ArinvInvNum
            SET @ArinvdInvSeq = @ArinvInvSeq
            SET @ArinvdDistSeq = @TDistSeq
            SET @ArinvdAcct = @TEndDisc
            SET @ArinvdAcctUnit1 = @TEndDiscUnit1
            SET @ArinvdAcctUnit2 = @TEndDiscUnit2
            SET @ArinvdAcctUnit3 = @TEndDiscUnit3
            SET @ArinvdAcctUnit4 = @TEndDiscUnit4

            IF  @InvCred = 'I'
               SET @ArinvdAmount = @ArinvdAmount - (@TDiscAmount)
            ELSE
               SET @ArinvdAmount = @ArinvdAmount + (@TDiscAmount)
            SET @ArinvdAmount = ROUND(@ArinvdAmount, @CurrencyPlaces)

            SET @ArinvdRowPointer = NewId()
            INSERT INTO @TmpArinvd (
                 cust_num
               , inv_num
               , inv_seq
               , dist_seq
               , acct
               , acct_unit1
               , acct_unit2
               , acct_unit3
               , acct_unit4
               , amount
               , new
               , RowPointer
               )
            VALUES(
                 @ArinvdCustNum
               , @ArinvdInvNum
               , @ArinvdInvSeq
               , @ArinvdDistSeq
               , @ArinvdAcct
               , @ArinvdAcctUnit1
               , @ArinvdAcctUnit2
               , @ArinvdAcctUnit3
               , @ArinvdAcctUnit4
               , @ArinvdAmount
               , 1
               , @ArinvdRowPointer
               )
         END
         ELSE
         BEGIN
            IF  @InvCred = 'I'
               SET @ArinvdAmount = @ArinvdAmount - (@TDiscAmount)
            ELSE
               SET @ArinvdAmount = @ArinvdAmount + (@TDiscAmount)

            UPDATE @TmpArinvd
            SET amount = ROUND(@ArinvdAmount, @CurrencyPlaces)
            WHERE RowPointer = @ArinvdRowPointer
         END
      END /* IF @TEndDisc IS NOT NULL AND @InvHdrDisc <> 0.0 */
      ELSE
      BEGIN
         IF @TEndDisc IS NULL AND @InvHdrDisc <> 0.0
         BEGIN
            SET @Infobar = NULL
            EXEC @Severity = dbo.MsgAppSp @Infobar OUTPUT, 'E=NoExistFor1'
               , '@arinvd.acct'
               , '@arparms'
               , '@arparms.sales_disc_acct'
               , @ArparmsSalesDiscAcct

            IF @Severity<>0
               GOTO EXIT_SP
         END
      END

      /* POST MISC CHARGES */
      IF @CoMiscCharges <> 0
      BEGIN
         SET @TDistSeq = @TDistSeq + 5
         SET @ArinvdCustNum   = @ArinvCustNum
         SET @ArinvdInvNum    = @ArinvInvNum
         SET @ArinvdInvSeq    = @ArinvInvSeq
         SET @ArinvdDistSeq   = @TDistSeq
         SET @ArinvdAcct      = @ArparmsMiscAcct
         SET @ArinvdAcctUnit1 = @ArparmsMiscAcctUnit1
         SET @ArinvdAcctUnit2 = @ArparmsMiscAcctUnit2
         SET @ArinvdAcctUnit3 = @ArparmsMiscAcctUnit3
         SET @ArinvdAcctUnit4 = @ArparmsMiscAcctUnit4
         SET @ArinvdAmount    = @CoMiscCharges
         SET @InvHdrMiscAcct      = @ArparmsMiscAcct
         SET @InvHdrMiscAcctUnit1 = @ArparmsMiscAcctUnit1
         SET @InvHdrMiscAcctUnit2 = @ArparmsMiscAcctUnit2
         SET @InvHdrMiscAcctUnit3 = @ArparmsMiscAcctUnit3
         SET @InvHdrMiscAcctUnit4 = @ArparmsMiscAcctUnit4
         SET @ArinvdAmount = ROUND(@ArinvdAmount, @CurrencyPlaces)

         SET @ArinvdRowPointer = NewId()
         INSERT INTO @TmpArinvd (
              cust_num
            , inv_num
            , inv_seq
            , dist_seq
            , acct
            , acct_unit1
            , acct_unit2
            , acct_unit3
            , acct_unit4
            , amount
            , new
            , RowPointer
            )
         VALUES(
              @ArinvdCustNum
            , @ArinvdInvNum
            , @ArinvdInvSeq
            , @ArinvdDistSeq
            , @ArinvdAcct
            , @ArinvdAcctUnit1
            , @ArinvdAcctUnit2
            , @ArinvdAcctUnit3
            , @ArinvdAcctUnit4
            , @ArinvdAmount
            , 1
            , @ArinvdRowPointer
            )
      END

      /* POST FREIGHT */
      IF @CoFreight <> 0
      BEGIN

         --create arinvd
         -- INITIALIZING VARS FOR TABLE INSERT

         SET @TDistSeq = @TDistSeq + 5
         SET @ArinvdCustNum            = @ArinvCustNum
         SET @ArinvdInvNum             = @ArinvInvNum
         SET @ArinvdInvSeq             = @ArinvInvSeq
         SET @ArinvdDistSeq            = @TDistSeq
         SET @ArinvdAcct                = @ArparmsFreightAcct
         SET @ArinvdAcctUnit1          = @ArparmsFreightAcctUnit1
         SET @ArinvdAcctUnit2          = @ArparmsFreightAcctUnit2
         SET @ArinvdAcctUnit3          = @ArparmsFreightAcctUnit3
         SET @ArinvdAcctUnit4          = @ArparmsFreightAcctUnit4
         SET @ArinvdAmount              = @CoFreight
         SET @InvHdrFreightAcct       = @ArparmsFreightAcct
         SET @InvHdrFreightAcctUnit1 = @ArparmsFreightAcctUnit1
         SET @InvHdrFreightAcctUnit2 = @ArparmsFreightAcctUnit2
         SET @InvHdrFreightAcctUnit3 = @ArparmsFreightAcctUnit3
         SET @InvHdrFreightAcctUnit4 = @ArparmsFreightAcctUnit4
         SET @ArinvdAmount = ROUND(@ArinvdAmount, @CurrencyPlaces)

         SET @ArinvdRowPointer = NewId()
         INSERT INTO @TmpArinvd (
              cust_num
            , inv_num
            , inv_seq
            , dist_seq
            , acct
            , acct_unit1
            , acct_unit2
            , acct_unit3
            , acct_unit4
            , amount
            , new
            , RowPointer
         )
         VALUES (
              @ArinvdCustNum
            , @ArinvdInvNum
            , @ArinvdInvSeq
            , @ArinvdDistSeq
            , @ArinvdAcct
            , @ArinvdAcctUnit1
            , @ArinvdAcctUnit2
            , @ArinvdAcctUnit3
            , @ArinvdAcctUnit4
            , @ArinvdAmount
            , 1
            , @ArinvdRowPointer
         )

         UPDATE @TmpArinv
            SET  sales_tax = ROUND(@ArinvSalesTax, @CurrencyPlaces)
               , sales_tax_2 = ROUND(@ArinvSalesTax2, @CurrencyPlaces)
               , misc_charges = ROUND(@ArinvMiscCharges, @CurrencyPlaces)
               , freight = ROUND(@ArinvFreight, @CurrencyPlaces)
               , amount = ROUND(@ArinvAmount, @CurrencyPlaces)
         WHERE RowPointer = @ArinvRowPointer
      END /* IF @CoFreight <> 0 */

      UPDATE #TmpInvHdr
         SET misc_charges       = @InvHdrMiscCharges
           , freight            = @InvHdrFreight
           , price              = @InvHdrPrice
           , prepaid_amt        = @InvHdrPrepaidAmt
           , tot_comm_due       = @InvHdrTotCommDue
           , comm_calc          = @InvHdrCommCalc
           , comm_base          = @InvHdrCommBase
           , comm_due           = @InvHdrCommDue
           , misc_acct          = @InvHdrMiscAcct
           , misc_acct_unit1    = @InvHdrMiscAcctUnit1
           , misc_acct_unit2    = @InvHdrMiscAcctUnit2
           , misc_acct_unit3    = @InvHdrMiscAcctUnit3
           , misc_acct_unit4    = @InvHdrMiscAcctUnit4
           , freight_acct       = @InvHdrFreightAcct
           , freight_acct_unit1 = @InvHdrFreightAcctUnit1
           , freight_acct_unit2 = @InvHdrFreightAcctUnit2
           , freight_acct_unit3 = @InvHdrFreightAcctUnit3
           , freight_acct_unit4 = @InvHdrFreightAcctUnit4
           , disc_amount        = @TDiscAmount
      WHERE RowPointer = @InvHdrRowPointer

      /* POST TAX DISTRIBUTION */
---------------
        INSERT INTO @Arinvd (
              cust_num
            , inv_num
            , inv_seq
            , dist_seq
            , acct
            , acct_unit1
            , acct_unit2
            , acct_unit3
            , acct_unit4
            , amount
            , tax_system
            , tax_code
            , tax_code_e
            , tax_basis
            , new
            , RowPointer
         )
       SELECT
              @ArinvCustNum
            , @ArinvInvNum
            , @ArinvInvSeq
            , @TDistSeq
            , inv_stax.stax_acct
            , inv_stax.stax_acct_unit1
            , inv_stax.stax_acct_unit2
            , inv_stax.stax_acct_unit3
            , inv_stax.stax_acct_unit4
            , CASE WHEN  @InvCred = 'I' THEN isnull(inv_stax.sales_tax, 0) ELSE (isnull(inv_stax.sales_tax, 0) * -1) END
            , isnull(inv_stax.tax_system, 0)
            , inv_stax.tax_code
            , inv_stax.tax_code_e
            , CASE WHEN  @InvCred = 'I' THEN isnull(inv_stax.tax_basis, 0) ELSE (isnull(inv_stax.tax_basis, 0) * -1) END
            , 1
            , NewId()
      FROM @TmpInvStax AS inv_stax
      WHERE inv_stax.inv_num = @InvHdrInvNum
        AND inv_stax.inv_seq = @InvHdrInvSeq

      UPDATE @Arinvd
      SET dist_seq = @TDistSeq,
       @TDistSeq = @TDistSeq + 5

      SET @ArinvdAmount = ROUND(@ArinvdAmount, @CurrencyPlaces)

      INSERT INTO @TmpArinvd(
              cust_num
            , inv_num
            , inv_seq
            , dist_seq
            , acct
            , acct_unit1
            , acct_unit2
            , acct_unit3
            , acct_unit4
            , amount
            , tax_system
            , tax_code
            , tax_code_e
            , tax_basis
            , new
            , RowPointer
         )
      SELECT
              cust_num
            , inv_num
            , inv_seq
            , dist_seq
            , acct
            , acct_unit1
            , acct_unit2
            , acct_unit3
            , acct_unit4
            , amount
            , tax_system
            , tax_code
            , tax_code_e
            , tax_basis
            , new
            , RowPointer
        FROM @Arinvd

      DELETE FROM @Arinvd

      SET @ArinvdCustNum   = @ArinvCustNum
      SET @ArinvdInvNum    = @ArinvInvNum
      SET @ArinvdInvSeq    = @ArinvInvSeq
      SET @ArinvdDistSeq   = @TDistSeq

      SELECT
          @ArinvdAcct      = inv_stax.stax_acct
        , @ArinvdAcctUnit1 = inv_stax.stax_acct_unit1
        , @ArinvdAcctUnit2 = inv_stax.stax_acct_unit2
        , @ArinvdAcctUnit3 = inv_stax.stax_acct_unit3
        , @ArinvdAcctUnit4 = inv_stax.stax_acct_unit4
        , @ArinvdAmount    = CASE WHEN  @InvCred = 'I' THEN isnull(inv_stax.sales_tax, 0) ELSE (isnull(inv_stax.sales_tax, 0) * -1) END
        , @ArinvdTaxSystem = isnull(inv_stax.tax_system, 0)
        , @ArinvdTaxCode   = inv_stax.tax_code
        , @ArinvdTaxCodeE  = inv_stax.tax_code_e
        , @ArinvdTaxBasis  = CASE WHEN  @InvCred = 'I' THEN isnull(inv_stax.tax_basis, 0) ELSE (isnull(inv_stax.tax_basis, 0) * -1) END
        , @ArinvdRowPointer = NewId()
      FROM @TmpInvStax AS inv_stax
      WHERE inv_stax.inv_num = @InvHdrInvNum
        AND inv_stax.inv_seq = @InvHdrInvSeq

      SET @CoPrepaidT    = @CoPrepaidT   + @InvHdrPrepaidAmt
      SET @CoMChargesT   = @CoMChargesT + @InvHdrMiscCharges
      SET @CoFreightT    = @CoFreightT   + @InvHdrFreight
      SET @CoSalesTaxT   = @CoSalesTaxT  + @TSalesTax
      SET @CoSalesTaxT2  = @CoSalesTaxT2 + @TSalesTax2
      SET @CoMiscCharges = 0
      SET @CoSalesTax    = CASE WHEN  @InvCred = 'I'
                                THEN @CoSalesTax - dbo.MinAmt(@CoSalesTax, @TSalesTax)
                                ELSE @CoSalesTax
                           END

      SET @CoSalesTax2   = CASE WHEN  @InvCred = 'I'
                                THEN  @CoSalesTax2 - dbo.MinAmt(@CoSalesTax2, @TSalesTax2)
                                ELSE @CoSalesTax2
                           END
      SET @CoFreight     = 0
      SET @CoInvoiced    = 1
      SET @CoPrepaidAmt  = @CoPrepaidAmt - @InvHdrPrepaidAmt

      IF EXISTS (SELECT * FROM @TmpCo AS TC WHERE TC.RowPointer = @CoRowPointer)
         UPDATE @TmpCo
            SET prepaid_t    = @CoPrepaidT
              , m_charges_t  = @CoMChargesT
              , freight_t    = @CoFreightT
              , sales_tax_t  = @CoSalesTaxT
              , sales_tax_t2 = @CoSalesTaxT2
              , misc_charges = @CoMiscCharges
              , sales_tax    = @CoSalesTax
              , sales_tax_2  = @CoSalesTax2
              , freight      = @CoFreight
              , invoiced     = @CoInvoiced
              , prepaid_amt  = @CoPrepaidAmt
         WHERE RowPointer = @CoRowPointer
      ELSE
         INSERT INTO @TmpCo (
              prepaid_t
            , m_charges_t
            , freight_t
            , sales_tax_t
            , sales_tax_t2
            , misc_charges
            , sales_tax
            , sales_tax_2
            , freight
            , invoiced
            , prepaid_amt
            , RowPointer
            )
         SELECT
              @CoPrepaidT
            , @CoMChargesT
            , @CoFreightT
            , @CoSalesTaxT
            , @CoSalesTaxT2
            , @CoMiscCharges
            , @CoSalesTax
            , @CoSalesTax2
            , @CoFreight
            , @CoInvoiced
            , @CoPrepaidAmt
            , @CoRowPointer

      IF  @InvCred = 'C'
      BEGIN
         EXEC @Severity = dbo.SumCoSp @CoCoNum, @Infobar output
         IF @Severity <> 0
            GOTO EXIT_SP
      END

      IF @CoLcrNum IS NOT NULL
      BEGIN
         SET @CustLcrRowPointer = NULL
         SET @CustLcrShipValue  = 0

         SELECT
              @CustLcrRowPointer = cust_lcr.RowPointer
         FROM cust_lcr
         WHERE cust_lcr.cust_num = @CoCustNum
           AND cust_lcr.lcr_num = @CoLcrNum

         IF @CustLcrRowPointer IS NOT NULL
         BEGIN
            SET @CustLcrShipValue = @InvHdrMiscCharges + @InvHdrFreight +
                                    @TSalesTax + @TSalesTax2

            IF EXISTS (SELECT * FROM @TmpCustLcr AS TCL WHERE TCL.RowPointer = @CustLcrRowPointer)
               UPDATE @TmpCustLcr
                  SET ship_value = ship_value + @CustLcrShipValue
               WHERE RowPointer = @CustLcrRowPointer
            ELSE
               INSERT INTO @TmpCustLcr (
                    ship_value
                  , RowPointer
               )
               VALUES (
                    @CustLcrShipValue
                  , @CustLcrRowPointer)
         END
      END

      IF @ArparmUsePrePrintedForms = 0
         GOTO EXIT_WHILE
      ELSE
      BEGIN
         SET @CurrLinesDoc = @CurrLinesDoc + @LinesPerDoc
         SET @IsPartialCommit = 1
         SET @LocatorVar = 2
         GOTO UPDATE_FILES
         LOCATION_2:
      END

   END /* WHILE (@LoopLinesDoc > @CurrLinesDoc or @ArparmUsePrePrintedForms = 0) */

EXIT_WHILE:
   SET @Severity = 0

END
CLOSE      co_Crs
DEALLOCATE co_Crs /*co_Crs*/

SET @LocatorVar = 0

UPDATE_FILES:

   IF @RecordsFound = 0
      GOTO EXIT_SP

   EXEC @Severity = dbo.DefineVariableSp 'SkipCoitemUpdateCustOrderBal', '1', @Infobar

   INSERT INTO arinv (
        cust_num
      , inv_num
      , type
      , post_from_co
      , co_num
      , inv_date
      , tax_code1
      , tax_code2
      , terms_code
      , acct
      , acct_unit1
      , acct_unit2
      , acct_unit3
      , acct_unit4
      , ref
      , description
      , exch_rate
      , use_exch_rate
      , fixed_rate
      , pay_type
      , draft_print_flag
      , due_date
      , sales_tax
      , sales_tax_2
      , misc_charges
      , freight
      , amount
      , RowPointer
      , approval_status
      , include_tax_in_price
      , apply_to_inv_num
      , builder_inv_orig_site
      , builder_inv_num      )      
   SELECT
        cust_num
      , inv_num
      , type
      , post_from_co
      , co_num
      , inv_date
      , tax_code1
      , tax_code2
      , terms_code
      , acct
      , acct_unit1
      , acct_unit2
      , acct_unit3
      , acct_unit4
      , ref
      , description
      , exch_rate
      , use_exch_rate
      , fixed_rate
      , pay_type
      , draft_print_flag
      , due_date
      , sales_tax
      , sales_tax_2
      , misc_charges
      , freight
      , amount + ISNULL((select sum(surcharge) from inv_item_surcharge where inv_item_surcharge.inv_num = ta.inv_num),0)
      , RowPointer
      , approval_status
      , include_tax_in_price
      , apply_to_inv_num
      , @BuilderInvOrigSite
      , @BuilderInvNum      
   FROM @TmpArinv as ta

   SET @TmpArinvCustNum = NULL
   SET @TmpArinvInvNum  = NULL
   SET @TmpArinvInvSeq  = NULL
   SET @TmpArinvInvDate = NULL
   SET @TmpArinvTermsCode = NULL

   DECLARE MultipleDueDateCrs CURSOR LOCAL STATIC FOR
   SELECT
      cust_num
     ,inv_num
     ,inv_seq
     ,inv_date
     ,terms_code
   FROM @TmpArinv
   WHERE terms_use_multiDueDates = 1 AND type = 'I'
   OPEN MultipleDueDateCrs
   WHILE @Severity = 0
   BEGIN
      FETCH MultipleDueDateCrs INTO
           @TmpArinvCustNum
         , @TmpArinvInvNum
         , @TmpArinvInvSeq
         , @TmpArinvInvDate
         , @TmpArinvTermsCode

      IF @@FETCH_STATUS = -1
         BREAK
      /* Multiple Due Dates */

      EXEC @Severity = dbo.AddARDueDateSeqSp
                    @pCustNum      = @TmpArinvCustNum
                  , @pInvNum       = @TmpArinvInvNum
                  , @pInvSeq       = @TmpArinvInvSeq
                  , @pInvoiceDate  = @TmpArinvInvDate
                  , @pTermsCode    = @TmpArinvTermsCode
                  , @pMultiDueDateFlag = 1
                  , @Infobar       = @Infobar   OUTPUT

      IF @Severity <> 0
         GOTO EXIT_SP
      /* Multiple Due Dates */

   END
   CLOSE      MultipleDueDateCrs
   DEALLOCATE MultipleDueDateCrs

   INSERT INTO inv_hdr (
        inv_num
      , inv_seq
      , cust_num
      , cust_seq
      , co_num
      , inv_date
      , terms_code
      , ship_code
      , cust_po
      , weight
      , qty_packages
      , disc
      , bill_type
      , state
      , exch_rate
      , use_exch_rate
      , tax_code1
      , tax_code2
      , frt_tax_code1
      , frt_tax_code2
      , msc_tax_code1
      , msc_tax_code2
      , tax_Date
      , ship_date
      , slsman
      , ec_code
      , misc_charges
      , freight
      , price
      , prepaid_amt
      , tot_comm_due
      , comm_calc
      , comm_base
      , comm_due
      , misc_acct
      , misc_acct_unit1
      , misc_acct_unit2
      , misc_acct_unit3
      , misc_acct_unit4
      , freight_acct
      , freight_acct_unit1
      , freight_acct_unit2
      , freight_acct_unit3
      , freight_acct_unit4
      , cost
      , RowPointer
      , disc_amount
      , builder_inv_orig_site
      , builder_inv_num      )     
   SELECT
        inv_num
      , inv_seq
      , cust_num
      , cust_seq
      , co_num
      , inv_date
      , terms_code
      , ship_code
      , cust_po
      , weight
      , qty_packages
      , disc
      , bill_type
      , state
      , exch_rate
      , use_exch_rate
      , tax_code1
      , tax_code2
      , frt_tax_code1
      , frt_tax_code2
      , msc_tax_code1
      , msc_tax_code2
      , tax_Date
      , ship_date
      , slsman
      , ec_code
      , misc_charges
      , freight
      , price
      , prepaid_amt
      , tot_comm_due
      , comm_calc
      , comm_base
      , comm_due
      , misc_acct
      , misc_acct_unit1
      , misc_acct_unit2
      , misc_acct_unit3
      , misc_acct_unit4
      , freight_acct
      , freight_acct_unit1
      , freight_acct_unit2
      , freight_acct_unit3
      , freight_acct_unit4
      , cost
      , RowPointer
      , disc_amount
      , @BuilderInvOrigSite
      , @BuilderInvNum            
   FROM #TmpInvHdr

   -- Begin/End Invoice Number
   -- Enter record in TrackRows for printing
   INSERT INTO TrackRows (
     SessionId
   , TrackedOperType
   , RowPointer )
   SELECT
     @ProcessId
   , 'inv_hdr'
   , RowPointer
   FROM #TmpInvHdr
   WHERE cust_tp_paper_invoice = 1

   INSERT INTO inv_pro (
        inv_num
      , co_num
      , co_line
      , seq
      , amount
      , description
      , applied)
   SELECT
        inv_num
      , co_num
      , co_line
      , seq
      , amount
      , description
      , applied
   FROM @TmpInvPro
   WHERE new = 1

   UPDATE inv_pro
      SET inv_pro.applied = TIP.applied
   FROM inv_pro INNER JOIN @TmpInvPro as TIP on TIP.RowPointer = inv_pro.RowPointer
   WHERE new = 0

   INSERT INTO arinvd (
        cust_num
      , inv_num
      , inv_seq
      , dist_seq
      , acct
      , acct_unit1
      , acct_unit2
      , acct_unit3
      , acct_unit4
      , ref_type
      , ref_num
      , ref_line_suf
      , ref_release
      , amount
      , tax_system
      , tax_code
      , tax_code_e
      , tax_basis
      , RowPointer
      )
   SELECT
        cust_num
      , inv_num
      , inv_seq
      , dist_seq
      , acct
      , acct_unit1
      , acct_unit2
      , acct_unit3
      , acct_unit4
      , ref_type
      , ref_num
      , ref_line_suf
      , ref_release
      , amount
      , tax_system
      , tax_code
      , tax_code_e
      , tax_basis
      , RowPointer
   FROM @TmpArinvd
   WHERE new = 1

   UPDATE arinvd
      SET arinvd.amount = TAD.amount
   FROM arinvd INNER JOIN @TmpArinvd as TAD on TAD.RowPointer = arinvd.RowPointer
   WHERE TAD.new = 0
  IF @TaxparmsCashRound > 0
  begin
  IF (@TermsRowPointer IS NOT NULL AND @TermsCashOnly = 1)
         BEGIN
         UPDATE arinvd
         SET arinvd.amount = round(arinvd.amount / @TaxparmsCashRound, 0, 1) * @TaxparmsCashRound
         end
  end

   INSERT INTO inv_item (
        inv_num
      , inv_seq
      , inv_line
      , co_num
      , co_line
      , co_release
      , item
      , disc
      , price
      , process_ind
      , cons_num
      , tax_code1
      , tax_code2
      , tax_date
      , cust_po
      , qty_invoiced
      , cost
      , sales_acct
      , sales_acct_unit1
      , sales_acct_unit2
      , sales_acct_unit3
      , sales_acct_unit4
      , orig_inv_num
      , reason_text
      , excise_tax_percent )
   SELECT
        inv_num
      , inv_seq
      , inv_line
      , co_num
      , co_line
      , co_release
      , item
      , disc
      , price
      , process_ind
      , cons_num
      , tax_code1
      , tax_code2
      , tax_date
      , cust_po
      , qty_invoiced
      , cost
      , sales_acct
      , sales_acct_unit1
      , sales_acct_unit2
      , sales_acct_unit3
      , sales_acct_unit4
      , orig_inv_num
      , reason_text
      , excise_tax_percent
   FROM #TmpInvItem

   INSERT INTO inv_stax (
        inv_num
      , inv_seq
      , seq
      , tax_code
      , sales_tax
      , stax_acct
      , stax_acct_unit1
      , stax_acct_unit2
      , stax_acct_unit3
      , stax_acct_unit4
      , inv_date
      , cust_num
      , cust_seq
      , tax_basis
      , tax_system
      , tax_rate
      , tax_jur
      , tax_code_e)
   SELECT
        inv_num
      , inv_seq
      , seq
      , tax_code
      , sales_tax
      , stax_acct
      , stax_acct_unit1
      , stax_acct_unit2
      , stax_acct_unit3
      , stax_acct_unit4
      , inv_date
      , cust_num
      , cust_seq
      , tax_basis
      , tax_system
      , tax_rate
      , tax_jur
      , tax_code_e
   FROM @TmpInvStax

   /* COMPUTE COMMISSION
      (Note: any changes here see also co/invpostp.p & co/invposta.p)

      Also create any required EDI invoice records (edi_inv_hdr & edi_inv_item)     */
   DECLARE inv_hdr_Crs CURSOR LOCAL STATIC FOR
   SELECT
        inv_num
      , co_num
      , exch_rate
      , curr_code
      , curr_places
      , RowPointer
      , edi_cust
      , cust_num
      , cust_seq
   FROM #TmpInvHdr
   OPEN inv_hdr_Crs
   WHILE @Severity = 0
   BEGIN
      FETCH inv_hdr_Crs INTO
           @InvHdrInvNum
         , @InvHdrCoNum
         , @InvHdrExchRate
         , @CurrencyCurrCode
         , @CurrencyPlaces
         , @InvHdrRowPointer
         , @CustomerEdiCust
         , @InvHdrCustNum
         , @InvHdrCustSeq
      IF @@FETCH_STATUS = -1
          BREAK

      SET @InvHdrCommBase = 0
      SET @InvHdrCommCalc = 0
      SET @InvHdrCommDue = 0
      SET @InvHdrTotCommDue = 0

      DECLARE co_sls_comm_Crs CURSOR LOCAL STATIC FOR
      SELECT
           co_sls_comm.slsman
         , co_sls_comm.rev_percent
         , co_sls_comm.comm_percent
         , co_sls_comm.co_line
      FROM co_sls_comm
      WHERE co_sls_comm.co_num = @InvHdrCoNum

      OPEN co_sls_comm_Crs
      WHILE @Severity = 0
      BEGIN
         FETCH co_sls_comm_Crs INTO
              @CoSlsCommSlsman
            , @CoSlsCommRevPercent
            , @CoSlsCommCommPercent
            , @CoSlsCommCoLine
         IF @@FETCH_STATUS = -1
             BREAK

         SET @CoSlsCommRevPercent  = ISNULL(@CoSlsCommRevPercent, 0)

         SET @TCurSlsman = @CoSlsCommSlsman
         SET @TLoopCounter = 0

         --While @TCurSlsman <> ''
         WHILE @TCurSlsman IS NOT NULL
         BEGIN
            SET @TLoopCounter = @TLoopCounter + 1
            IF @TLoopCounter > 20
            BEGIN
               SET @Infobar = NULL
               EXEC @Severity = dbo.MsgAppSp @Infobar OUTPUT, 'E=Recursive1'
                  , '@slsman'
                  , '@slsman.slsman'
                  , @TCurSlsman

               GOTO EXIT_SP
            END

            SET @SlsmanRowPointer = NULL
            SET @SlsmanSlsman     = NULL
            SET @SlsmanSlsmangr   = NULL
            SET @SlsmanRefNum     = NULL

            SELECT
                 @SlsmanRowPointer = slsman.RowPointer
               , @SlsmanSlsman     = slsman.slsman
               , @SlsmanSlsmangr   = slsman.slsmangr
               , @SlsmanRefNum     = slsman.ref_num
            FROM slsman WITH (UPDLOCK)
            WHERE slsman.slsman = @TCurSlsman

            IF @SlsmanRowPointer IS NULL
            BEGIN
               SET @Infobar = NULL
               EXEC @Severity = dbo.MsgAppSp @Infobar OUTPUT, 'E=NoExist1'
                  , '@slsman'
                  , '@slsman.slsman'
                  , @TCurSlsman

               GOTO EXIT_SP
            END

            SET @TCommCalc = 0
            SET @TCommBase = 0
            SET @TCommBaseTot = 0

            EXEC @Severity = dbo.CommCalcSp
                 @InvCred, /* Invoice/Credit Memo */
                 @InvHdrInvNum,                   /* Invoice Number */
                 @InvHdrCoNum,
                 @TCurSlsman,
                 @CurrencyCurrCode,
                 @CurrencyPlaces,
                 @InvHdrExchRate,
                 @CoSlsCommRevPercent,
                 @CoSlsCommCommPercent,
                 @CoSlsCommCoLine,
                 NULL,                            /* rowid for rma processing */
                 @TCommBaseTot OUTPUT,
                 @TCommCalc    OUTPUT,            /* Commission Amount */
                 @TCommBase    OUTPUT,            /* Commission Base */
                 @Infobar      OUTPUT
            , @ParmsSite = @ParmsSite

            IF @Severity <> 0
            BEGIN
               SET @Infobar = NULL
               EXEC @Severity = dbo.MsgAppSp @Infobar OUTPUT, 'E=CmdFailed1'
                  , '@commtran'
                  , '@co'
                  , '@co.co_num'
                  , @CoCoNum
               GOTO EXIT_SP
            END

            SET @CoSlsCommCommPercent = NULL     -- Set commission percent to null for manager, which will cause the
                                                 -- manager to get paid according to the default % in their commtab
                                                 -- table record.

            SET @InvHdrTotCommDue = @InvHdrTotCommDue + @TCommCalc

            /* update inv-hdr with inv-hdr.slsman calculations only */
            IF ISNULL(@InvHdrSlsman, NCHAR(1)) = ISNULL(@TCurSlsman, NCHAR(1))
            BEGIN
               SET @InvHdrCommCalc = @InvHdrCommCalc + @TCommCalc
               SET @InvHdrCommBase = @TCommBase
               SET @InvHdrCommDue = @InvHdrCommDue +
                                    (CASE WHEN @CoparmsDueOnPmt=0 OR @InvCred = 'C'
                                          THEN @TCommCalc
                                          ELSE 0
                                          END)
            END

            IF @TCommCalc <> 0
            BEGIN
               --create commdue
               SET @CommdueInvNum       = @InvHdrInvNum
               SET @CommdueCoNum        = @InvHdrCoNum
               SET @CommdueSlsman       = @TCurSlsman
               SET @CommdueCustNum      = @InvHdrCustNum
               SET @CommdueCommDue      = (CASE WHEN @CoparmsDueOnPmt = 0 OR @InvCred = 'C'
                                                THEN @TCommCalc
                                                ELSE 0
                                                END)
               SET @CommdueDueDate      = @InvHdrInvDate
               SET @CommdueCommCalc     = @TCommCalc
               SET @CommdueCommBase     = @TCommBaseTot
               SET @CommdueCommBaseSlsp = @TCommBase
               SET @CommdueSeq          = 1
               SET @CommduePaidFlag     = 0
               SET @CommdueSlsmangr     = (CASE WHEN ISNULL(@SlsmanSlsman, NCHAR(1)) =
                                                     ISNULL(@SlsmanSlsmangr, NCHAR(1))
                                                     AND @TLoopCounter > 1
                                                THEN NULL
                                                ELSE @SlsmanSlsmangr
                                                END)
               SET @CommdueStat = 'P'
               SET @CommdueRef          = (CASE WHEN  @InvCred = 'I'
                                                  THEN @TInvLabel
                                                ELSE @TCrMemo
                                                END)
               SET @CommdueEmpNum       = @SlsmanRefNum

               INSERT INTO @TmpCommdue (
                    inv_num
                  , co_num
                  , slsman
                  , cust_num
                  , comm_due
                  , due_date
                  , comm_calc
                  , comm_base
                  , comm_base_slsp
                  , seq
                  , paid_flag
                  , slsmangr
                  , stat
                  , ref
                  , emp_num )
               VALUES(
                    @CommdueInvNum
                  , @CommdueCoNum
                  , @CommdueSlsman
                  , @CommdueCustNum
                  , @CommdueCommDue
                  , @CommdueDueDate
                  , @CommdueCommCalc
                  , @CommdueCommBase
                  , @CommdueCommBaseSlsp
                  , @CommdueSeq
                  , @CommduePaidFlag
                  , @CommdueSlsmangr
                  , @CommdueStat
                  , @CommdueRef
                  , @CommdueEmpNum )
            END /* IF @TCommCalc <> 0 */

            /* DON'T INCREASE TWICE
               IF HE MANAGES HIMSELF AND HE MADE THE SALE */

            IF @TLoopCounter <= 1 OR ISNULL(@CoSlsCommSlsman, NCHAR(1)) <> ISNULL(@SlsmanSlsmangr, NCHAR(1))
            BEGIN
               IF EXISTS (SELECT * FROM @TmpSlsman AS TS WHERE TS.RowPointer = @SlsmanRowPointer)
                  UPDATE @TmpSlsman
                     SET sales_ytd = sales_ytd + @TCommBase
                       , sales_ptd = sales_ptd + @TCommBase
                  WHERE RowPointer = @SlsmanRowPointer
               ELSE
                  INSERT INTO @TmpSlsman (
                       sales_ytd
                     , sales_ptd
                     , RowPointer)
                  SELECT
                       @TCommBase
                     , @TCommBase
                     , @SlsmanRowPointer
            END /* IF @TLoopCounter <= 1 ... */

            /* PROCESS MANAGER OF SALESMAN NEXT ITERATION, IF SALESMAN IS
               HIS/HER OWN MANAGER, ONLY PROCESS IF THE MANAGER MADE THE
               SALE THEMSELF (.ie t-loop-counter = 1). */
            SET @TCurSlsman =  CASE WHEN ISNULL(@SlsmanSlsman, NCHAR(1)) = ISNULL(@SlsmanSlsmangr, NCHAR(1)) AND
                                         @TLoopCounter > 1
                                    THEN NULL
                                    ELSE @SlsmanSlsmangr
                               END
         END /* WHILE @TCurSlsman IS NOT NULL */
      END /* WHILE @Severity = 0 */
      CLOSE      co_sls_comm_Crs
      DEALLOCATE co_sls_comm_Crs /* for each co-sls-comm */

      UPDATE #TmpInvHdr
         SET comm_base = @InvHdrCommBase
           , comm_calc = @InvHdrCommCalc
           , comm_due  = @InvHdrCommDue
           , tot_comm_due = @InvHdrTotCommDue
      WHERE RowPointer = @InvHdrRowPointer

      /* EDI */
      SET @PrintFlag = 1
      IF @CustomerEdiCust = 1
      BEGIN
         EXEC @Severity = dbo.EdiOutObDriverSp
              @PTranType = 'INVC'          /* Invoice */
            , @PCustNum  = @InvHdrCustNum
            , @PCustSeq  = @InvHdrCustSeq
            , @PInvNum   = @InvHdrInvNum
            , @PCoNum    = NULL
            , @PBolNum   = NULL
            , @PFlag     = @PrintFlag OUTPUT   /* Trading partner's print flag */
            , @Infobar   = @Infobar   OUTPUT

         IF @Severity <> 0
            GOTO EXIT_SP
      END
   END
   CLOSE      inv_hdr_Crs
   DEALLOCATE inv_hdr_Crs

   UPDATE inv_hdr
      SET inv_hdr.comm_base = TIH.comm_base
   FROM inv_hdr INNER JOIN #TmpInvHdr AS TIH ON TIH.RowPointer = inv_hdr.RowPointer
   where isnull(inv_hdr.comm_base, 0) != TIH.comm_base

   INSERT INTO commdue (
        inv_num
      , co_num
      , slsman
      , cust_num
      , comm_due
      , due_date
      , comm_calc
      , comm_base
      , comm_base_slsp
      , seq
      , paid_flag
      , slsmangr
      , stat
      , ref
      , emp_num )
   SELECT
        inv_num
      , co_num
      , slsman
      , cust_num
      , comm_due
      , due_date
      , comm_calc
      , comm_base
      , comm_base_slsp
      , seq
      , paid_flag
      , slsmangr
      , stat
      , ref
      , emp_num
   FROM @TmpCommdue

   INSERT INTO custdrft (
        cust_num
      , inv_date
      , payment_due_date
      , amount
      , exch_rate
      , stat
      , inv_num
      , co_num
      , bank_code
      , cust_bank
      , bank_number
      , bank_addr##1
      , bank_addr##2
      , branch_code
      , print_flag)
   SELECT
        cust_num
      , inv_date
      , payment_due_date
      , amount
      , exch_rate
      , stat
      , inv_num
      , co_num
      , bank_code
      , cust_bank
      , bank_number
      , bank_addr##1
      , bank_addr##2
      , branch_code
      , print_flag
   FROM @TmpCustdrft

   /* ADJUST COMMISSION EARNED/DUE AMOUNT
    * on commdue row that was generated when original invoice was generated
    */
   IF @CoparmsDueOnPmt = 1 AND
      @InvCred = 'C'
   BEGIN
      -- loop through new credit memos created
      DECLARE inv_hdr_Crs2 CURSOR LOCAL STATIC FOR
      SELECT
        TIH.RowPointer
      , TIH.inv_num
      , TIH.inv_seq
      , TIH.inv_date
      , TIH.price
      , TIH.prepaid_amt
      , TIH.freight
      , TIH.misc_charges
      , co.apply_to_inv_num
      FROM #TmpInvHdr TIH
      INNER JOIN co WITH (READUNCOMMITTED)
      ON co.co_num = TIH.co_num
      AND co.apply_to_inv_num IS NOT NULL

      OPEN inv_hdr_Crs2

      WHILE @Severity = 0
      BEGIN
         FETCH inv_hdr_Crs2 INTO
           @TInvHdrRowPointer
         , @TInvHdrInvNum
         , @TInvHdrInvSeq
         , @TInvHdrInvDate
         , @TInvHdrPrice
         , @TInvHdrPrepaidAmt /* will be zero for CR memos */
         , @TInvHdrFreight
         , @TInvHdrMiscCharges
         , @CoApplyToInvNum

         IF @@FETCH_STATUS = -1
            BREAK

         SET @TCRMemoTaxAmt = 0
         SET @TCRMemoSum = 0

         SELECT @TCRMemoTaxAmt = SUM(ISNULL(inv_stax.sales_tax, 0))
         FROM  inv_stax
         WHERE inv_stax.inv_num = @TInvHdrInvNum
         AND   inv_stax.inv_seq = @TInvHdrInvSeq

         SET @TCRMemoSum = ISNULL(@TInvHdrPrice, 0) + ISNULL(@TInvHdrPrepaidAmt, 0) -
                           ISNULL(@TInvHdrFreight, 0) - ISNULL(@TInvHdrMiscCharges, 0) - ISNULL(@TCRMemoTaxAmt, 0)

         IF ISNULL(@CoApplyToInvNum, '') <> '' AND
            CASE WHEN dbo.IsInteger(@CoApplyToInvNum) = 1 THEN CONVERT(BIGINT, @CoApplyToInvNum) ELSE 1 END > 0
         BEGIN
            SELECT
              @OInvHdrRowpointer  = NULL
            , @OInvHdrInvNum      = NULL
            , @OInvHdrInvSeq      = 0
            , @OInvHdrPrice       = 0
            , @OInvHdrPrepaidAmt  = 0
            , @OInvHdrFreight     = 0
            , @OInvHdrMiscCharges = 0
            , @OTaxAmt            = 0
            , @OInvSum            = 0

            SELECT
              @OInvHdrRowpointer  = inv_hdr.rowpointer
            , @OInvHdrInvNum      = inv_hdr.inv_num
            , @OInvHdrInvSeq      = inv_hdr.inv_seq
            , @OInvHdrPrice       = inv_hdr.price
            , @OInvHdrPrepaidAmt  = inv_hdr.prepaid_amt
            , @OInvHdrFreight     = inv_hdr.freight
            , @OInvHdrMiscCharges = inv_hdr.misc_charges
            FROM  inv_hdr WITH (UPDLOCK)
            WHERE inv_hdr.inv_num = @CoApplyToInvNum
            AND   inv_hdr.inv_seq = 0

            IF @@ROWCOUNT <> 1
               SET @OInvHdrRowpointer = NULL

            IF @OInvHdrRowpointer IS NOT NULL
            BEGIN
               SELECT @OTaxAmt = SUM(ISNULL(inv_stax.sales_tax, 0))
               FROM  inv_stax
               WHERE inv_stax.inv_num = @OInvHdrInvNum
               AND   inv_stax.inv_seq = @OInvHdrInvSeq

               SET @OInvSum = ISNULL(@OInvHdrPrice, 0) + ISNULL(@OInvHdrPrepaidAmt, 0) -
                              ISNULL(@OInvHdrFreight, 0) - ISNULL(@OInvHdrMiscCharges, 0) - ISNULL(@OTaxAmt, 0)

               IF @OInvSum = 0
                  SET @OInvSum = 1

               SET @TPerCent = CASE WHEN ABS(@TCRMemoSum) / @OInvSum > 1.0 THEN 1.0
                                    ELSE ABS(@TCRMemoSum) / @OInvSum
                               END

               DECLARE commdue_crs CURSOR LOCAL STATIC FOR
               SELECT
                 commdue.due_date
               , ISNULL(commdue.comm_due, 0)
               , ISNULL(commdue.comm_calc, 0)
               , commdue.rowpointer
               FROM  commdue WITH (UPDLOCK)
               WHERE commdue.inv_num = @CoApplyToInvNum

               OPEN commdue_crs
               WHILE 1 = 1
               BEGIN
                  FETCH commdue_crs INTO
                    @CommdueDueDate
                  , @CommdueCommDue
                  , @CommdueCommCalc
                  , @CommdueRowpointer

                  IF @@FETCH_STATUS <> 0
                     BREAK

                  SET @CommdueDueDate = @TInvHdrInvDate
                  SET @CommdueCommDue = CASE WHEN @CommdueCommCalc >= 0
                                                THEN dbo.MinAmt(@CommdueCommCalc, @CommdueCommDue + ROUND((@CommdueCommCalc * @TPerCent), @DomCurrencyPlaces))
                                             ELSE dbo.MaxAmt(@CommdueCommCalc, @CommdueCommDue + ROUND((@CommdueCommCalc * @TPerCent), @DomCurrencyPlaces))
                                        END

                  UPDATE commdue
                  SET
                    due_date = @CommdueDueDate
                  , comm_due = @CommdueCommDue
                  WHERE rowpointer = @CommdueRowpointer
               END
               CLOSE commdue_crs
               DEALLOCATE commdue_crs

            END /* IF @OInvHdrRowpointer IS NOT NULL */

         END /* IF CASE WHEN dbo.IsInteger(@OldApplyToInvNum) = 1 */

      END /* inv_hdr_Crs2 WHILE @Severity = 0 */
      CLOSE inv_hdr_Crs2
      DEALLOCATE inv_hdr_Crs2

   END /* IF @CoparmsDueOnPmt = 1 */

   UPDATE co_ship
      SET co_ship.qty_invoiced = TCS.qty_invoiced,
          co_ship.qty_returned = TCS.qty_returned
   FROM co_ship INNER JOIN @TmpCoShip as TCS on TCS.RowPointer = co_ship.RowPointer AND
                                                TCS.upd_del_flag = 'U'

   DELETE co_ship
   FROM co_ship INNER JOIN @TmpCoShip AS TCS ON TCS.RowPointer = co_ship.RowPointer AND
                                                TCS.upd_del_flag = 'D'

   UPDATE pckitem
      SET pckitem.inv_num = TPI.inv_num
   FROM pckitem INNER JOIN @TmpPckitem AS TPI ON TPI.RowPointer = pckitem.RowPointer

   UPDATE serial
      SET serial.inv_num = TS.inv_num
   FROM serial INNER JOIN @TmpSerial AS TS ON TS.ser_num = serial.ser_num AND TS.item = serial.item

   exec dbo.SetTriggerStateSp
     @SkipReplicating  = 0
   , @SkipBase         = 1
   , @ScopeProcess     = 1
   , @PreviousState    = @SavedState OUTPUT
   , @Infobar          = @Infobar OUTPUT
   , @SkipAllReplicate = 0
   , @SkipAllUpdate    = 0
   UPDATE progbill
      SET progbill.invc_flag = TPB.invc_flag
   FROM progbill INNER JOIN @TmpProgbill AS TPB ON TPB.RowPointer = progbill.RowPointer
   exec dbo.RestoreTriggerStateSp
     @ScopeProcess = 1
   , @SavedState   = @SavedState
   , @Infobar      = @Infobar OUTPUT

   declare sarbCrs cursor local static for
   select item
   , inv_date
   , price
   , qty_invoiced
   from @SarbWrt

   open sarbCrs

   while 1 = 1
   begin
      fetch sarbCrs into
        @InvItemItem
      , @InvHdrInvDate
      , @DPrice
      , @InvItemQtyInvoiced

      if @@fetch_status != 0
         break

      EXEC @Severity = dbo.SarbWrtSp
        @InvItemItem
      , @InvHdrInvDate
      , @DPrice
      , @InvItemQtyInvoiced
   end
   close sarbCrs
   deallocate sarbCrs

   UPDATE item
      SET item.last_inv = TI.last_inv
   FROM item INNER JOIN @TmpItem AS TI ON TI.Rowpointer = item.RowPointer

   UPDATE itemwhse
      SET itemwhse.sales_ptd = ISNULL(itemwhse.sales_ptd, 0) + TI.sales_ptd
        , itemwhse.sales_ytd = ISNULL(itemwhse.sales_ytd, 0) + TI.sales_ytd
   FROM itemwhse INNER JOIN @TmpItemwhse AS TI ON TI.Rowpointer = itemwhse.RowPointer

   if @AllOrdersLocalSite = 1
      exec dbo.SetTriggerStateSp
        @SkipReplicating  = 0
      , @SkipBase         = 1
      , @ScopeProcess     = 1
      , @PreviousState    = @SavedState OUTPUT
      , @Infobar          = @Infobar OUTPUT
      , @SkipAllReplicate = 0
      , @SkipAllUpdate    = 0
   UPDATE coitem
      SET coitem.ship_date = TC.ship_date
        , coitem.prg_bill_app = TC.prg_bill_app
        , coitem.qty_invoiced = TC.qty_invoiced
        , coitem.qty_returned = TC.qty_returned
   FROM coitem INNER JOIN @TmpCoitem AS TC ON TC.RowPointer = coitem.RowPointer
   if @AllOrdersLocalSite = 1
      exec dbo.RestoreTriggerStateSp
        @ScopeProcess = 1
      , @SavedState   = @SavedState
      , @Infobar      = @Infobar OUTPUT

   EXEC dbo.UndefineVariableSp 'SkipCoitemUpdateCustOrderBal', @Infobar

   UPDATE slsman
      SET slsman.sales_ytd = slsman.sales_ytd + TS.sales_ytd
        , slsman.sales_ptd = slsman.sales_ptd + TS.sales_ptd
   FROM slsman INNER JOIN @TmpSlsman AS TS ON TS.RowPointer = slsman.RowPointer

   UPDATE cust_lcr
      SET cust_lcr.ship_value = cust_lcr.ship_value + TCL.ship_value
   FROM cust_lcr INNER JOIN @TmpCustLcr AS TCL ON TCL.RowPointer = cust_lcr.RowPointer

   IF @ReleaseTmpTaxTables = 1
      EXEC dbo.ReleaseTmpTaxTablesSp @SessionId

   UPDATE co
      SET co.prepaid_t = TC.prepaid_t
        , co.m_charges_t = TC.m_charges_t
        , co.freight_t  = TC.freight_t
        , co.sales_tax_t = TC.sales_tax_t
        , co.sales_tax_t2 = TC.sales_tax_t2
        , co.misc_charges = TC.misc_charges
        , co.sales_tax  = TC.sales_tax
        , co.sales_tax_2 = TC.sales_tax_2
        , co.freight = TC.freight
        , co.invoiced = TC.invoiced
        , co.prepaid_amt = TC.prepaid_amt
   FROM co INNER JOIN @TmpCo AS TC ON TC.RowPointer = co.RowPointer


EXIT_SP:

if @BeginTranCount = 0 and @@trancount > 0
   if @Severity > 0
      ROLLBACK TRANSACTION
   else
      COMMIT TRANSACTION

if @Severity > 0
   set @IsPartialCommit = 0

if @IsPartialCommit = 1
begin
   set @IsPartialCommit = 0

   delete @TmpArinv
   delete @TmpArinvd
   delete #TmpInvHdr
   delete @TmpInvPro
   delete #TmpInvItem
   delete @TmpInvStax
   delete @TmpCommdue
   delete @TmpSlsman
   delete @TmpCustdrft
   delete @TmpCoShip
   delete @TmpPckitem
   delete @TmpSerial
   delete @TmpProgbill
   delete @SarbWrt
   delete @TmpItem
   delete @TmpItemwhse
   delete @TmpCoitem
   delete @TmpCustLcr
   delete @TmpCo

   if @BeginTranCount = 0
      BEGIN TRANSACTION

   IF @LocatorVar = 1
      GOTO LOCATION_1
   IF @LocatorVar = 2
      GOTO LOCATION_2
end

drop table #TmpInvHdr
drop table #TmpInvItem

IF @ReleaseTmpTaxTables = 1
   EXEC dbo.ReleaseTmpTaxTablesSp @SessionId

RETURN @Severity
GO


