USE [KPI_App]
GO

/****** Object:  StoredProcedure [dbo].[EXTGEN_Rpt_OrderVerificationSp]    Script Date: 08/30/2017 15:48:40 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


/* $Header: /ApplicationDB/Stored Procedures/Rpt_OrderVerificationSp.sp 152   3/27/15 2:15p Cajones $  */
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

/* Katena Customizations
   SL9.00.30  K1 (Scan on Katena1)  JFranz    Mon Feb 27, 2017
       Get Item warehouse from coitem record
*/

/* $Archive: /ApplicationDB/Stored Procedures/Rpt_OrderVerificationSp.sp $
 *
 * SL9.00 152 192300 Cajones Fri Mar 27 14:15:57 2015
 * Cannot print Order Verification Report with option Print Planning Materials, error: String or binary data would be truncated
 * Issue 192300
 * - Modified select from CoDConfig function to only take the first 40 characters of the @PCoitemFeatStr.
 * - This @PCoitemFeatStr field is only used to determine visibility on a few detail lines.
 *
 * SL9.00 151 188008 csun Wed Feb 04 04:03:30 2015
 * Issue#188008
 * RS7090,Add 3 new columns for report dataset.
 *
 * SL9.00 150 190567 Lchen3 Mon Feb 02 03:54:54 2015
 * Order Verification not including Freight in Tax Calculation when tax code says to
 * issue 190567
 * use @TcAmtFreight2 when calculate freight tax, it is same as @TcAmtFreight, but @TcAmtFreight will be set to 0 in the first loop, but we will calculate the tax in the last loop.
 *
 * SL9.00 149 188504 pgross Wed Dec 31 10:51:31 2014
 * Invoice amounts are not correct when there is a line discount and amount format with no decimals.
 * round order discount
 *
 * SL9.00 148 188369 pgross Thu Dec 18 11:32:33 2014
 * ensure that surcharges are rounded with the proper currency
 *
 * SL9.00 147 188369 pgross Thu Dec 18 10:57:08 2014
 * round the extended surcharge amount
 *
 * SL9.00 146 188391 Dmcwhorter Tue Dec 16 15:52:00 2014
 * Wrong Surcharge amount when using Unit of Measure Conversion.
 * 188391 - Consider uom conversion on surcharges.
 *
 * SL9.00 145 188121 jzhou Wed Dec 03 04:20:01 2014
 * Issues with formatting of Simple and Detail templates
 * Issue 188121:
 * Use new function DisplayAddressForReportFooter to get the address for report footer.
 *
 * SL9.00 144 188021 jzhou Tue Nov 25 02:15:22 2014
 * E-mail field does not exist on A/R Parms form
 * Issue 188021: 
 * Add URL and Email Address to the result set.
 *
 * SL9.00 143 187946 Igui Fri Nov 21 01:38:05 2014
 * Report fails on the background when printing Simple or Detail template
 * issue 187946
 *
 * SL9.00 142 187529 Igui Thu Nov 20 21:45:41 2014
 * RS7082 Construction
 * issue 187529
 * add parameter @URL.
 *
 * SL9.01 140 187529 Ehe Fri Nov 14 03:38:12 2014
 * RS7082 Construction
 * RS7082(issue 187529)
 * add parameter @DelTermDescription.
 *
 * SL9.00 139 180744 Dyang2 Fri Jun 13 02:18:55 2014
 * Sales Tax not correct on Order Verification when there is a multi-level tax code
 * Issue 180744: Tax Calculation will be executed for whole CO, so will be calculated for last line, not for every co line, and change the currency place parameter from hard code 8 to currency definition.
 *
 * SL9.00 138 151474 pgross Wed Apr 23 16:54:53 2014
 * Order verification does not print for lines shipping from another site
 * added multi-site tax capability
 *
 * SL9.00 137 176919 Mding2 Fri Mar 21 03:28:01 2014
 * Fix issue 176919.
 * use parm.key = 0 when read data from parms
 *
 * SL9.00 136 176893 Jgao1 Fri Mar 21 01:20:28 2014
 * Currency format on Net Amout field is not correct on Order Verification Report
 * 176893: use customer currency format to replace domestic currency format.
 *
 * SL9.00 135 176506 Jgao1 Tue Mar 11 03:08:44 2014
 * The decimal numbers are not displayed correctly on Order Verification Report
 * 176506: Add fields DomTotCurrencyFormat and DomTotCurrencyPlaces
 *
 * SL9.00 134 176368 pgross Wed Mar 05 16:49:09 2014
 * Sales tax is incorrect on Order Verification Report
 * round the individual line tax amounts and apply rounding differences to the last line
 *
 * SL9.00 133 176127 pgross Fri Feb 28 15:08:53 2014
 * Total amount of Order Verification Report is not correct
 * round the tax totals
 *
 * SL9.00 132 173352 calagappan Fri Jan 03 15:37:00 2014
 * Total on Order Verification Report is incorrect if Order includes Lines for Configured Items and Configuration Details is set to External or All.
 * Include Kit components in report output table instead of separate table
 *
 * SL9.00 131 171385 Mding2 Thu Dec 26 03:35:07 2013
 * Germany Country Pack - Report layout changes
 * Issue 171385 - Re-write logic for using Alternate Address Report Formatting.
 *
 * SL9.00 130 171385 Ezi Tue Dec 03 21:32:50 2013
 * Germany Country Pack - Report layout changes
 * Issue 171385 - Clean some codes.
 *
 * SL9.00 129 171385 jzhou Tue Dec 03 04:45:08 2013
 * Germany Country Pack - Report layout changes
 * Issue 171385:
 * Add the logic for displaying the company address in a line when select the Use Alternate Address Report Format option.
 *
 * SL8.04 128 167860 Cliu Thu Sep 05 05:42:42 2013
 * Sales amount is cut off instead of rounding on Order Verification Report
 * Issue 167860 
 * Change @CurrencyPlaces back to 8,  and remove the round function for @PriceBeforeTax.
 *
 * SL8.04 127 165732 Igui Tue Aug 27 06:04:25 2013
 * Item content information line should be set a hidden condition when an item is eligible to make references for item content or not.
 * Issue 165732 - Add Item Content field into sp to set a hidden condition for reports when an item is eligible to make references for item content or not.
 *
 * SL8.04 126 165732 Igui Thu Aug 22 04:04:41 2013
 * Item content information line should be set a hidden condition when an item is eligible to make references for item content or not.
 * Issue 165732 - order the select columns
 *
 * SL8.04 125 165732 Igui Tue Aug 20 03:06:25 2013
 * Item content information line should be set a hidden condition when an item is eligible to make references for item content or not.
 * Issue 165732 - Add output field item_content (1 = the definition of item contents that provide the basis for the calculation of surcharges included with items that are purchased from vendors and sold to customers.)
 *
 * SL8.04 124 166131 Sxu Sun Aug 18 23:24:39 2013
 * Tax price is cut off instead of rounding on Order Verification Report
 * Issue 166131 - Change @CurrencyPlaces back to 8, so the total tax amount will round up base on sum of all lines. This is the same as Customer Orders and Order Invoicing.
 *
 * SL8.04 123 162919 jzhou Thu Jul 04 04:28:18 2013
 * Code of how to get the value of overview seems not consistent in some sps
 * Issue 162919:
 * Format the codes.
 *
 * SL8.04 122 162919 jzhou Wed Jul 03 04:58:31 2013
 * Issue 162919:
 * To make the codes in SPs which get the value of overview from the item_lang.overview be consistent.
 *
 * SL8.04 121 159127 Dmcwhorter Thu Jun 27 08:58:35 2013
 * Price rounding is incorrect on Customer order lines as it multiplies by qty ordered before rounding
 * RS6172 - Alternate Net Price Calculation.
 *
 * SL8.04 120 163569 pgross Thu Jun 13 15:10:41 2013
 * Sales Tax not rounding correctly on Order Verification Report
 * pass @CurrencyPlaces as parameter to TaxCalcSp instead of 8
 *
 * SL8.04 118 161238 calagappan Sun May 05 15:44:08 2013
 * Incorrect VAT Number recorded on Order Verification
 * Display customer Bill To and Ship To EU Code, Tax registration number and Branch ID
 *
 * SL8.04 114 RS5135 Lliu Sun Mar 17 22:37:03 2013
 * RS5135:Add PromotionCode and Adjustment the order for the paramters.
 *
 * SL8.04 113 157551 Cajones Thu Feb 07 15:39:11 2013
 * Notes for CO headers won't print in Order verification Report if CO has no CO Lines
 * Issue 157551
 * Moved logic that sets @CoNoteExistsFlag, @BillToCustNoteExistsFlag and @ShipToCustNoteExistsFlag before the CoItemAllCrs logic.
 *
 * SL8.04 112 RS4615 Jmtao Thu Dec 27 02:25:45 2012
 * RS4615 (Multi - Add Site within a Site Functionality). replace tab with 3 spaces, delete enter at the last of the file
 *
 * SL8.04 109 155119 pgross Wed Nov 07 13:58:03 2012
 * does not print if there are other customer ship to's with edi profile
 * pick up the EDI flag from the ShipTo customer instead of the BillTo
 *
 * SL8.04 108 151424 Cjin2 Fri Aug 24 02:55:55 2012
 * Tax on Freight is doubled when Tax Code is also entered on the Order Line
 * 151424: set @LocalInit to 1 when calling TaxCalcSp to delete already processed record exemption tax basis records.
 *
 * SL8.04 107 RS5200 Dlai Tue Aug 21 22:49:31 2012
 * RS5200 add PrintItemOverview flag to output itemoverview information and trim trailling space
 *
 * SL8.04 106 rs5458 Vlitmano Thu Aug 09 14:51:42 2012
 * RS5458 - changed the logic to return null for coitem.due_date for portal created orders.
 *
 * SL8.03 105 149147 Clarsco Fri May 11 18:48:46 2012
 * Order Verification Report Total is incorrect when Order includes a Line with Serial Reservations
 * Fixed Issue 149147
 * Removed Config Detail from Serial Detail lines.
 * Serial Detail lines 2 and up have zero value for net_amount, sales_tax1, sales_tax2, co_disc and Price_before_tax.
 * 1st Config Detail lines has value for net_amount, sales_tax1, sales_tax2, co_disc and Price_before_tax, only when there are no Serial Detail lines.
 *
 * SL8.03 104 148376 Clarsco Tue May 01 18:19:14 2012
 * Order Verification Report Total is incorrect when Order includes a Line for a Configured Item.
 * Fixed Issue 148376
 * Config Detail lines 2 and up have zero value for net_amount, sales_tax1, sales_tax2, co_disc and Price_before_tax.
 *
 * SL8.03 103 146452 Mewing Mon Apr 16 17:38:45 2012
 * Issue fro RS 5397 implementation of PO-CO Automation
 * RS5397 Auto Create PO-CO Across Sites
 *
 * SL8.03 101 147232 Cajones Fri Mar 09 16:19:09 2012
 * Order Verificaton report only displays tax on last line of customer order.
 * Issue 147232
 * Removed some logic that was using a Fudge variable to fix a rounding issue (124327).  Also Changed call to TaxCalcSp so that an 8 is passed in the CurrencyPlaces parameter which causes TaxCalcSp to not round.
 *
 * SL8.03 100 146747 Cajones Thu Mar 01 11:57:09 2012
 * Order Verification report - Grand total incorrect when adding configured item
 * Issue 146747
 * Modified logic that updates the last line of a feature item to NOT update these fields(sales_tax1, sales_tax2, co_disc, net_amount)
 *
 * SL8.03 99 144861 pgross Fri Feb 17 15:58:12 2012
 * Using setting from bill to edi profile not ship to edi profile
 * look at the EDI flags of the ShipTo customer instead of the BillTo customer
 *
 * SL8.03 98 141847 pgross Wed Nov 09 10:54:10 2011
 * Order Verification Report shows incorrect Sales Tax
 * clear out tmp_tax_basis between lines
 *
 * SL8.03 97 142634 Mmarsolo Mon Oct 03 09:39:48 2011
 * 142634 - Add else condition for multi-lingual item description
 *
 * SL8.03 96 140325 Dmcwhorter Fri Jul 15 15:08:59 2011
 * If no salesperson exists in CO, report will not print
 * 140325 - Modifiy check for salesperson range.
 *
 * SL8.03 95 RS4978 EGriffiths Fri Jul 15 10:15:13 2011
 * RS4978 - Corrected DataTypes
 *
 * SL8.03 94 137363 Dmcwhorter Thu Apr 14 15:19:54 2011
 * Header does not print on 2nd page
 * 137363 - Store header info on planning material records.
 *
 * SL8.03 93 RS5123 Cajones Wed Mar 23 10:20:58 2011
 * RS5123 - Added code to retrieve multi-lingual translations for the Terms Description, Ship Via Description, Item Description and Order Text
 *
 * SL8.03 92 rs3639 Jpan2 Thu Mar 03 00:09:42 2011
 * RS3639 if item is non inventory, get item description from coitem.
 *
 * SL8.03 91 134582 Cajones Mon Nov 29 14:52:53 2010
 * Order Verification Report run by Salesperson range returns records with no Salesperson.
 * Issue 134582
 * Modifed the ISNULL check to default either LowCharacter/HighCharacter instead of @SalespersonStarting/@SalespersonEnding
 *
 * SL8.03 90 129713 calagappan Wed Sep 01 16:18:07 2010
 * Sales Reps Name appears inconsistently on invoices
 * format employee name
 *
 * SL8.03 89 131933 pgross Tue Jul 20 17:04:22 2010
 * Order discount percent and amount display incorrectly
 * include the Discount Amount in the Total Price when calculating the Discount Percent
 *
 * SL8.03 88 131793 pgross Fri Jul 16 11:16:28 2010
 * Order Verification Report displays the wrong tax amount
 * clear out tmp_tax_calc between lines
 *
 * SL8.02 87 128675 Mewing Tue Apr 27 14:57:23 2010
 * Update Copyright to 2010
 *
 * SL8.02 86 128911 pgross Mon Apr 19 15:27:23 2010
 * Blanket customer order line releases are printed out of sequence when more then 10 releases exist.
 * prepend co_release with leading blanks
 *
 * SL8.02 85 128517 pgross Mon Apr 19 14:48:46 2010
 * Order Verification - lines shipping from other sites not on report printed from origin site.
 * altered how CO discount is computed
 *
 * SL8.02 84 rs4588 Dahn Thu Mar 04 16:31:37 2010
 * rs4588 copyright header changes.
 *
 * SL8.02 83 127974 Dmcwhorter Thu Mar 04 11:34:36 2010
 * Order Verification Report does not display Contact information if Ship To is anything other than 0.
 * 127974 - Include the cust_seq when selecting the customer record to obtain the ship-to contact from.
 *
 * SL8.02 82 126571 Dmcwhorter Mon Jan 04 15:42:29 2010
 * Cannot print Order Verification for Blanket Customer Orders
 * 126571 - Correct the selection of blanket COs.
 *
 * SL8.02 81 125187 Dmcwhorter Thu Nov 19 13:38:10 2009
 * Notes added to a CO line shipping from another site, are omitted from the order verification if the order is updated in the remote site.
 * 125187 - Set the NotesExistFlag from the current site's co line.
 *
 * SL8.02 80 124327 pgross Wed Sep 30 11:39:52 2009
 * Order verification Report - sales tax is rounding differently in order verification than on customer order.
 * improved handling of tax rounding differences
 *
 * SL8.02 79 124308 pgross Thu Sep 24 14:06:38 2009
 * Discount is changed to 100% when an amount discount is added to an order with lines shipping from another site.
 * Only print lines from the current site.
 * If none exist, print a blank line
 *
 * SL8.01 78 124030 pgross Mon Sep 14 14:57:50 2009
 * Order Verification Report - Terms code defaults from previous order with terms code.
 * moved SELECT statements into the Cursor statement which will properly initialize variables
 *
 * SL8.01 77 122386 bbopp Fri Jul 17 09:05:40 2009
 * AcknowledgeSalesOrder BOD needs error message
 * Issue 122386.
 * Rework trigger point call to remove the "OriginalApplicationArea" parameters.
 *
 * SL8.01 76 118696 bbopp Fri May 01 16:25:36 2009
 * Finish SyteLine / WebStore Interface
 * Issue 118696
 * Add Confirmation Number.
 *
 * SL8.01 75 118696 bbopp Thu Apr 30 15:11:33 2009
 * Finish SyteLine / WebStore Interface
 * Issue 118696
 * Add parameters to trigger point for OriginalApplicationArea.
 *
 * SL8.01 74 117154 Dmcwhorter Mon Jan 26 16:40:09 2009
 * The fix for issue 91480 was inadvertently removed.
 * 117154 - Pass both co_release and cast_co_release to report.
 *
 * SL8.01 73 116659 Djackson1 Thu Jan 15 13:11:28 2009
 * 116659 - Add ActionExpression to BOD Parameters
 *
 * SL8.01 72 115127 pgross Tue Dec 02 16:51:56 2008
 * Total does not print on Order Verification Report for configured items
 * corrected which @reportset record gets updated for configured items
 *
 * SL8.01 71 108343 flagatta Thu Nov 13 08:41:22 2008
 * Order Verification Report prints Order Blanket Release not in proper ascending sequence
 * Changed the datatype on the co_release column on @ReportSet table to be NVARCHAR.  108343
 *
 * SL8.01 70 rs3953 Vlitmano Tue Aug 26 19:02:21 2008
 * RS3953 - Changed a Copyright header?
 *
 * SL8.01 69 rs3953 Vlitmano Mon Aug 18 15:38:55 2008
 * Changed a Copyright header information(RS3959)
 *
 * SL8.01 68 110003 Debmcw Thu Jul 03 12:53:38 2008
 * SLCNFIG 8.0 does not print the Line on the Order Verification Report if there are no Components with External Print Codes
 * 110003 - Add an empty configset when no components are selected for printing.
 *
 * SL8.01 67 109676 Djackson1 Wed Jun 11 13:19:27 2008
 * 2 issues with the Sales Order BOD
 * 109676 Multiple BODs Created for the Same CO
 *
 * SL8.01 66 RS4088 dgopi Tue May 20 06:58:01 2008
 * Making modifications as per RS4088
 *
 * SL8.01 65 RS4032 Djackson1 Tue Apr 08 11:37:18 2008
 * Add BOD Creation On Print For SalesOrder
 *
 * SL8.01 64 107436 akottapp Thu Feb 07 02:41:41 2008
 * When you try to verify database for the Order Verification report, you receive error message "Violation of PRIMARY KEY Constratint 'PK_@stack_0F4E5A8e'.  Cannot insert duplicate key in object '#0E5A3655'. SQL State: 23000 Native Error: 2627"
 * Issue 107436 :
 * Add items to error log only if Task Id is not null.Otherwise report may fail to verify for some data with TaskId input as NULL.
 * Added a condition to make sure that the Divisor of Disount calculation is not zero.
 *
 * SL8.00 63 98490 ssalahud Wed Jan 02 09:52:42 2008
 * Invoice Distributions not= Posting Report not= Journal Entries - all three have different amounts
 * Issue 98490
 * Modified code to pass in @CurrencyPlacesfor @Places while calling TaxCalcSp and TaxPriceSeperationSp.
 *
 * SL8.00 62 106767 Debmcw Fri Dec 14 14:12:24 2007
 * Print order verification report and report is blank
 * 106767 - Log errors from Tax Calculation.
 *
 * SL8.00 61 106194 hcl-kumarup Thu Oct 25 01:16:32 2007
 * Tax wrong on Order Verification Report.
 * Checked-in for issue 106194
 * Passed 50 to TaxCalcSp for Currecy Places param . This is implemented according to CurrCnvtSp where 50 is used for "No Rounding at all"
 *
 * SL8.00 60 102025 hcl-tiwasun Thu Jul 12 06:51:09 2007
 * Item number does not print
 * Issue# 102025
 * Modify the name of Item Column of  @KitComponent Table variable from Item to Kit_Item.
 *
 * SL8.00 59 100204 flagatta Tue Jun 19 15:07:08 2007
 * Kit materials printing multiple times
 * Tie kit components to the line/release.  Issue 100204
 *
 * SL8.00 58 102579 hcl-jmishra Tue Jun 19 07:04:15 2007
 * Unable to successfully run this report
 * Issue 102579
 * Modify the select clause for CoAllCrs cursor so as to avoid
 * 'Divide by zero' error.
 *
 * SL8.00 57 102229 Hcl-tayamoh Thu May 31 06:39:16 2007
 * users tax id does not print on the order verification report
 * Issue 102229
 * Removed code to calculate  Customer FedId and userFedId and
 * added call for TaxIdSp to fetch the value of Customer FedId and userFedId.
 *
 * SL8.00 56 101845 hcl-singind Thu May 17 08:06:02 2007
 * Order Verification Report is not printing Customers tax id number
 * Issue # 101845
 * Modified the logic to get the FEDID number.
 *
 * SL8.00 55 100043 hcl-nautami Fri Mar 16 09:01:14 2007
 * Order Verification Report - quantity format only displays 2 decimal places to the right of the decimal.
 * Issue 100043:
 * Modified the Sps to output the format string and 'decimal places to round' in the reportset.
 *
 * SL8.00 54 RS2968 nkaleel Fri Feb 23 04:59:55 2007
 * changing copyright information(RS2968)
 *
 * SL8.00 53 97516 hcl-singind Thu Nov 09 03:38:07 2006
 * LCR not correct on Order Verification Report
 * Issue # 97516
 * Modified the code of sp so that LCR no is populated from co table instead of cust_lcr.
 *
 * SL8.00 52 97229 Hcl-tayamoh Wed Oct 25 04:45:10 2006
 * Sales Amounts are blank on Order Verification Report when last CO Line is a Configured Item
 * Issue 97229
 * When @PrintPlanningItemMaterials=1,
 * update statement's of @reportset table modified. SubQuery for selecting unique_val changed.
 *
 * SL8.00 51 97243 hcl-kumarup Fri Oct 13 07:20:03 2006
 * Order Verification is not calculating Sales Tax correctly
 * Checked-in for issue 97243
 * Passed @CurrencyPlaces as param to TaxCalcSp for currency places.
 *
 * SL8.00 50 96224 hcl-jmishra Fri Sep 29 04:54:59 2006
 * Total amount is not correct (difference 0.01) in Order Verification Report when the CO is "Include Tax in Price" .
 * Issue 96224
 * Modified the code of the SP so as to round off the values obtained after TaxPriceSeparationSp.
 *
 * SL8.00 49 95602 diwakar.cg Thu Aug 03 05:52:55 2006
 * "Print Kit Components" flag not being checked
 * Issue No 95602
 * Added column 'PrintKtonCustPaperWork'  column for @reportset Table variable for checking the Line items to be printed on the Customer Paper work.
 *
 * SL8.00 48 95505 diwakar.cg Tue Aug 01 17:34:02 2006
 * Error when trying to run report
 * Issue No 95505
 * Select columns from temporary table #Comp_Matl joining with @ReportSet TableVariable
 *
 * SL8.00 47 RS1164 diwakar.cg Fri Jul 21 10:18:57 2006
 * RS1164
 * a.Changed select condition joining to #Comp_Matl for building final recordset
 *
 * SL8.00 46 RS1164 ajith.nair Mon Jul 17 08:53:33 2006
 * RS1164
 * Replaced 'PhantomItemSp' with new generalized Sp 'GetKitItemBOMSP'
 * for getting Kit Item components
 *
 * SL8.00 45 RS2968 prahaladarao.hs Wed Jul 12 01:48:24 2006
 * RS 2968, Name change CopyRight Update.
 *
 * SL8.00 44 RS1164 diwakar.cg Wed Jun 28 02:02:52 2006
 * RS1164
 *
 * SL8.00 43 92656 rajesh.mg Fri Mar 03 05:03:38 2006
 * Euro total does not print when specified
 * 92656
 * Initialised @TEuroTotal variable to 0. Because value was not adding when
 * initital value set to NULL.
 *
 * SL8.00 42 90942 madhanprasad.s Fri Mar 03 00:46:53 2006
 * Fed ID inconsistency
 * 90942
 * These are the following changes made,
 * a> Code is added to populate value for the FED ID field.
 * b> The lenght value of taxreg#1 and taxreg#2 is changed from 25 to 132.
 *
 * SL8.00 38 92654 hcl-singnee Thu Feb 23 01:50:02 2006
 * Report fails when sorting by Salesperson
 * Issue# 92654
 * Modified sorting of records from @reportset table according to option selected (Salesman or CustomerOrder).
 *
 * SL7.05 37 91818 NThurn Fri Jan 06 17:57:22 2006
 * Inserted standard External Touch Point call.  (RS3177)
 *
 * SL7.04 36 91534 Grosphi Tue Dec 27 13:22:03 2005
 * corrected calculation of order-level discount percent
 *
 * SL7.04 35 91480 Hcl-mehtviv Wed Dec 21 01:59:46 2005
 * Definition of the @reportset (or @ResultSet) table variable in the stored procedure behind the Order Verification report.
 * Issue  91480:
 * Variable declaration in the table @reportset for the field  "co_release"  changed from nvarchar(4) to int.
 *
 * SL7.04 34 89637 Hcl-tayamoh Wed Nov 30 16:30:31 2005
 * Backend stored procedure code cleanup for performance imrprovement
 * 89637
 *
 * SL7.04 33 90506 pcoate Wed Nov 23 10:11:00 2005
 * Issue 90506 - Corrected error handling.
 *
 * SL7.04 31 88495 Hcl-jainami Thu Aug 25 15:28:27 2005
 * Freight, sales tax, misc charges and total do not print on order verification if item is configured item
 * Checked-in for issue 88495:
 * Updated the Freight, Sales Tax, Misc. Charges, Totals etc. fields in @reportset table for Configured Items.
 *
 * SL7.04 30 86894 Hcl-jainami Tue May 17 15:00:13 2005
 * If both the "Print Ship To Notes" and "Print Bill To Notes" fields are checked, only the Ship To notes print
 * Checked-in for issue 86894:
 * Added code to display Bill To as well as Ship To Notes.
 *
 * SL7.04 29 87116 Hcl-kavimah Fri May 06 01:54:09 2005
 * Tax calculation is wrong on order verification report if Sytline Configurator is used to build the customer order.
 * Issue 87116,
 *
 * Reverted the changes made for Isue 74595 and made the required changes in the Report
 *
 * SL7.04 28 85980 Grosphi Fri Apr 22 10:51:46 2005
 * customer order discount is displayed incorrectly - rounding value incorrectly.
 * 1)  improved handling of order-level discount amount
 * 2)  removed unused variables
 * 3)  added index to @reportset for performance
 *
 * SL7.04 27 86057 Hcl-kavimah Fri Mar 11 00:03:51 2005
 * Tax not being printed on order verification report if shipment is from a different site.
 * Issue 86057
 * made changes to take data from reference site instead of original site
 *
 * SL7.04 26 85343 Grosphi Tue Feb 01 16:25:07 2005
 * allow for 55 characters in displayed feature string
 *
 * $NoKeywords: $
 */
CREATE PROCEDURE [dbo].[EXTGEN_Rpt_OrderVerificationSp]
(
   @CoTypeRegular                   ListYesNoType       = NULL,
   @CoTypeBlanket                   ListYesNoType       = NULL,
   @CoLineReleaseStat               NCHAR(200)          = NULL,
   @PrintItemCustItem               NCHAR(2)            = NULL,
   @PrintOrderText                  ListYesNoType       = NULL,
   @PrintStandardOrderText          ListYesNoType       = NULL,
   @PrintCompanyName                ListYesNoType       = NULL,
   @DisplayDate                     NCHAR(200)          = NULL,
   @DateToAppear                    DateType            = NULL,
   @DateToAppearOffset              DateOffsetType      = NULL,
   @PrintBlanketLineText            ListYesNoType       = NULL,
   @PrintBlanketLineDes             ListYesNoType       = NULL,
   @PrintLineReleaseNotes           ListYesNoType       = NULL,
   @PrintLineReleaseDes             ListYesNoType       = NULL,
   @PrintShipToNotes                ListYesNoType       = NULL,
   @printBillToNotes                ListYesNoType       = NULL,
   @PrintPlanningItemMaterials      ListYesNoType       = NULL,
   @IncludeSerialNumbers            ListYesNoType       = NULL,
   @PrintEuroValue                  ListYesNoType       = NULL,
   @PrintPrice                      ListYesNoType       = NULL,
   @Sortby                          NCHAR(1)            = NULL,
   @OrderStarting                   CoNumType           = NULL,
   @OrderEnding                     CoNumType           = NULL,
   @SalespersonStarting             SlsmanType          = NULL,
   @SalespersonEnding               SlsmanType          = NULL,
   @OrderLineStarting               GenericIntType      = NULL,
   @OrderReleaseStarting            GenericIntType      = NULL,
   @OrderLineEnding                 GenericIntType      = NULL,
   @OrderReleaseEnding              GenericIntType      = NULL,
   @ShowInternal                    ListYesNoType       = NULL,
   @ShowExternal                    ListYesNoType       = NULL,
   @PrintItemOverview               ListYesNoType       = NULL,
   @DisplayHeader                   ListYesNoType       = NULL,
   @ConfigDetails                   NChar(1)            = NULL,
   @TaskId                          TaskNumType         = NULL,
   @pSite                           SiteType            = NULL,
   @PrintDrawingNumber              ListYesNoType       = NULL,
   @PrintTax                        ListYesNoType       = NULL,
   @PrintDeliveryIncoTerms          ListYesNoType       = NULL,
   @PrintEUCode                     ListYesNoType       = NULL,
   @PrintOriginCode                 ListYesNoType       = NULL,
   @PrintCommodityCode              ListYesNoType       = NULL,
   @PrintCurrencyCode               ListYesNoType       = NULL,
   @PrintHeaderOnAllPages           ListYesNoType       = NULL,
   @PrintEndUserItem                ListYesNoType       = NULL
)AS
--  Crystal reports has the habit of setting the isolation level to dirty
-- read, so we'll correct that for this routine now.  Transaction management
-- is also not being provided by Crystal, so a transaction is started here.
BEGIN TRANSACTION
SET XACT_ABORT ON

IF dbo.GetIsolationLevel(N'OrderVerificationReport') = N'COMMITTED'
   SET TRANSACTION ISOLATION LEVEL READ COMMITTED
ELSE
   SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

-- A session context is created so session variables can be used.
DECLARE
  @RptSessionID  RowPointerType,
  @PromotionCode PromotionCodeType

   EXEC dbo.InitSessionContextSp
     @ContextName = 'Rpt_OrderVerificationSp'
   , @SessionID   = @RptSessionID OUTPUT
   , @Site        = @pSite

   SET @ShowInternal = ISNULL(@ShowInternal,1)
   SET @ShowExternal=ISNULL(@ShowExternal,1)
   SET @DisplayHeader =ISNULL(@DisplayHeader,1)
   SET @PrintItemOverview = ISNULL(@PrintItemOverview,0)
   SET @ConfigDetails =ISNULL(@ConfigDetails,'E')
   SET @Sortby                   = ISNULL(@Sortby,'C')
   SET @CoTypeRegular            = ISNULL(@CoTypeRegular,1)
   SET @CoTypeBlanket          = ISNULL(@CoTypeBlanket,1)
   SET @CoLineReleaseStat      = ISNULL(@CoLineReleaseStat, 'POFC')
   SET @PrintOrderText         = ISNULL(@PrintOrderText,0)
   SET @PrintStandardOrderText = ISNULL(@PrintStandardOrderText,0)
   SET @PrintCompanyName       = ISNULL(@PrintCompanyName,0)
   SET @DisplayDate            = ISNULL(@DisplayDate,'DP')

   SET @PrintBlanketLineText       = ISNULL(@PrintBlanketLineText, 1)
   SET @PrintPlanningItemMaterials = ISNULL(@PrintPlanningItemMaterials,1)
   SET @IncludeSerialNumbers       = ISNULL (@IncludeSerialNumbers, 0)
   SET @PrintEuroValue             = ISNULL (@PrintEuroValue, 0)
   SET @PrintPrice                 = ISNULL (@PrintPrice, 0)
   SET @PrintBlanketLineDes        = ISNULL(@PrintBlanketLineDes,1)

   SET @SalespersonStarting    = ISNULL(@SalespersonStarting, dbo.LowCharacter())
   SET @SalespersonEnding      = ISNULL(@SalespersonEnding, dbo.HighCharacter())
   SET @OrderStarting          = CASE WHEN @OrderStarting IS NULL THEN dbo.LowCharacter()  ELSE dbo.ExpandKyByType('CoNumType',@OrderStarting) END
   SET @OrderEnding            = CASE WHEN @OrderEnding   IS NULL THEN dbo.HighCharacter() ELSE dbo.ExpandKyByType('CoNumType',@OrderEnding)   END
   SET @OrderLineStarting      = ISNULL(@OrderLineStarting, dbo.LowInt())
   SET @OrderLineEnding        = ISNULL(@OrderLineEnding, dbo.HighInt())
   SET @OrderReleaseStarting   = ISNULL(@OrderReleaseStarting, dbo.LowInt())
   SET @OrderReleaseEnding     = ISNULL(@OrderReleaseEnding, dbo.HighInt())
   SET @DateToAppear           = ISNULL(@DateToAppear, dbo.GetSiteDate(getdate()))


   SET @PrintBlanketLineText       =ISNULL(@PrintBlanketLineText,1)
   SET @PrintBlanketLineDes        =ISNULL(@PrintBlanketLineDes,1)
   SET @PrintLineReleaseNotes      =ISNULL(@PrintLineReleaseNotes,1)
   SET @PrintLineReleaseDes        =ISNULL(@PrintLineReleaseDes,1)
   
   SET @PrintDrawingNumber         =ISNULL(@PrintDrawingNumber,0)
   SET @PrintTax                   =ISNULL(@PrintTax,0)
   SET @PrintDeliveryIncoTerms     =ISNULL(@PrintDeliveryIncoTerms,0)
   SET @PrintEUCode                =ISNULL(@PrintEUCode,0)
   SET @PrintOriginCode            =ISNULL(@PrintOriginCode,0)
   SET @PrintCommodityCode         =ISNULL(@PrintCommodityCode,0)
   SET @PrintCurrencyCode          =ISNULL(@PrintCurrencyCode,0)
   SET @PrintHeaderOnAllPages      =ISNULL(@PrintHeaderOnAllPages,0)
   SET @PrintEndUserItem           =ISNULL(@PrintEndUserItem,0)



DECLARE
   @Severity                   INT,
   @SessionId                  RowPointerType,
   @ReleaseTmpTaxTables        ListYesNoType,
   @PPartOfEuro                ListYesNoType,
   @TEuroTotal                 AmountType,
   @ItemDescription            DescriptionType,
   @OfficeAddr                 LongAddress,
   @OfficeAddrFooter           LongAddress,
   @BillTo                     LongAddress,
   @ShipTo                     LongAddress,
   @DropShipContact            ContactType,
   @DropShipAddr               LongAddress,
   @TcAmtLineNet               AmountType,
   @OLvlDiscLineNet            AmountType,
   @TcCprPrice                 AmountType,
   @TcAmtDisc                  LineDiscType,
   @TcAmtPrepaid               AmountType,
   @TcAmtUndisc                GenericDecimalType,
   @EuroConvAmount             GenericDecimalType,
   @TCustBillToTaxRegNum1      WideTextType,
   @TCustBillToTaxRegNum2      WideTextType,
   @TCustShipToTaxRegNum1      WideTextType,
   @TCustShipToTaxRegNum2      WideTextType,
   @TSlsman                    LongListType,
   @TcAmtSalesTax              AmountType,
   @TcAmtSalesTax2             AmountType,
   @TcAmtSales                 AmountType,
   @PrintFlag                  ListYesNoType,
   @TcAmtDiscount              AmountType,
   @TcAmtMisc                  AmountType,
   @TcAmtFreight               AmountType,
   @TcAmtMisc2                 AmountType,
   @TcAmtFreight2              AmountType,
   @TcAmtTotal                 AmountType,
   @THasText                   ListYesNoType,
   @ECurrencyPlaces            DecimalPlacesType,
   @ShipcodeDescription        DescriptionType,
   @TermsDescription           DescriptionType,
   @CoRowPointer               RowPointerType,
   @CoCoNum                    CoNumType,
   @CoSlsman                   SlsmanType,
   @SlsmanSlsman               SlsmanType,
   @CoCustPo                   CustPoType,
   @CoLcrNum                   LcrNumType,
   @CoCustNum                  CustNumType,
   @CoCustSeq                  CustSeqType,
   @CoQtyPackages              PackagesType,
   @CoOrderDate                DateType,
   @CoPrepaidAmt               AmountType,
   @CoMiscCharges              AmountType,
   @CoMChargesT                AmountType,
   @CoFreight                  AmountType,
   @CoFreightT                 AmountType,
   @CoTaxCode1                 TaxCodeType,
   @CoTaxCode2                 TaxCodeType,
   @CoFrtTaxCode1              TaxCodeType,
   @CoFrtTaxCode2              TaxCodeType,
   @CoMscTaxCode1              TaxCodeType,
   @CoMscTaxCode2              TaxCodeType,
   @CoShipCode                 ShipCodeType,
   @CoTermsCode                TermsCodeType,
   @CoUseExchRate              ListYesNoType,
   @CoExchRate                 ExchRateType,
   @CoPrepaidT                 AmountType,
   @CoOrigSite                 SiteType,
   @CoNoteExistsFlag           ListYesNoType,
   @CoDiscountType             ListAmountPercentType,
   @CoDiscAmount               AmountType,
   @Co_blnRowPointer           RowPointerType,
   @Co_blnNoteExistsFlag       ListYesNoType,
   @BillToCustNoteExistsFlag   ListYesNoType,
   @BillToCustomerRowPointer   RowPointerType,
   @ShipToCustNoteExistsFlag   ListYesNoType,
   @ShipToCustomerRowPointer   RowPointerType,
   @CoType                     CoTypeType,
   @CoDisc                     decimal(38, 30),--OrderDiscType
   @CoPortalOrder              ListYesNoType,
   @CustomerRowPointer         RowPointerType,
   @CustomerEdiCust            ListYesNoType,
   @CustomerCustNum            CustNumType,
   @CustomerCustSeq            CustSeqType,
   @CustaddrRowPointer         RowPointerType,
   @CustaddrCurrCode           CurrCodeType,
   @CustaddrFaxNum             PhoneType,
   @CurrencyDescription        DescriptionType,
   @CustomerLcrReqd            ListYesNoType,
   @SlsmanRowPointer           RowPointerType,
   @SlsmanOutside              ListYesNoType,
   @SlsmanRefNum               EmpVendNumType,
   @VendaddrRowPointer         RowPointerType,
   @VendaddrName               NameType,
   @EmployeeRowPointer         RowPointerType,
   @EmployeeName               EmpNameType,
   @CoitemRowPointer           RowPointerType,
   @CoitemShipSite             SiteType,
   @UserParmSite               SiteType,
   @TEuroUser                  ListYesNoType,
   @TEuroExists                ListYesNoType,
   @TBaseEuro                  ListYesNoType,
   @TEuroCurr                  CurrCodeType,
   @InfoBar                    InfoBarType,
   @OfficePhone                PhoneType,
   @OfficePhoneFooter          PhoneType,
   @CustomerContact1           ContactType,
   @CustomerContact2           ContactType,
   @PrepaidFlag                NVARCHAR(3),
   @TaxparmsNmbrOfSystems      TaxSystemsType,
   @TaxSystemPromptOnLine1     ListYesNoType,
   @TaxSystemPromptOnLine2     ListYesNoType,
   @TaxSystemTaxMode1          TaxModeType,
   @TaxSystemTaxMode2          TaxModeType,
   @CoitemQtyOrderedConv       QtyUnitNoNegType,
   @CoitemPriceConv            CostPrcType,
   @CoitemDisc                 LineDiscType,
   @CoitemItem                 ItemType,
   @CoitemTaxCode1             TaxCodeType,
   @CoitemTaxCode2             TaxCodeType,
   @CoitemTaxCode1Desc         DescriptionType,
   @CoitemTaxCode2Desc         DescriptionType,
   @CoitemCustItem             CustItemType,
   @CoitemCoLine               CoLineType,
   @CoitemCoRelease            CoReleaseType,
   @CoitemPromiseDate          DateType,
   @CoitemDueDate              DateType,
   @CoitemUM                   UMType,
   @CoitemFeatStr              FeatStrType,
   @CoitemCustNum              CustNumType,
   @CoitemCustSeq              CustSeqType,
   @CoitemConfigId             ConfigIdType,
   @CusttypeRowPointer         RowPointerType,
   @CusttypeTaxablePrice       TaxablePriceType,
   @ItemUWsPrice               CostPrcType,
   @RsvdInvRsvdNum             RsvdNumType,
   @SerialSerNum               SerNumType,
   @CustomerCustType           CustTypeType,
   @TodayDate                  DateType,
   @DisplayDateRep             Datetype,
   @BaseItemJob                JobType,
   @BaseItemSuffix             SuffixType,
   @CoParmsCoText1             ReportTxtType,
   @CoParmsCoText2             ReportTxtType,
   @CoParmsCoText3             ReportTxtType,
   @CoParmsUseAltPriceCalc     ListYesNoType,
   @CastCoitemCoRelease        NVARCHAR(5),
   @JobrouteJob                JobType,
   @JobrouteSuffix             SuffixType,
   @JobrouteOperNum            OperNumType,
   @FeatureDisplayQty          QtyPerType,
   @FeatureDisplayUM           UMType,
   @FeatureDisplayDesc         DescriptionType,
   @FeatureDisplayStr          FeatStrType,
   @LcrNum                     LcrNumType,
   @CoitemHasCfg               ListYesNoType,
   @Co_bln_Des                 DescriptionType,
   @coitemNoteExistsFlag       ListYesNoType ,
   @coitemDescription          DescriptionType,
   @coitemDescriptionOverview  ProductOverviewType,
   @Coitem_allNoteExistsFlag   ListYesNoType,
   @TaxItemLabel1              NVARCHAR(10),
   @TaxItemLabel2              NVARCHAR(10),
   @TaxAmtLabel1               NVARCHAR(10),
   @TaxAmtLabel2               NVARCHAR(10),
   @IncludeTaxInPrice          Listyesnotype,
   @PriceBeforeTax             AmountType,
   @xAmount                    AmountType,
   @CountryEcCode              EcCodeType,
   @TaxJurEcCode               EcCodeType,
   @TaxJurTaxRegNum            TaxRegNumType,
   @TaxJurBranchId             BranchIdType,
   @TTaxIDLabel1               NVARCHAR(10),
   @TTaxRegNum1                WideTextType,
   @HdrTaxCode1                TaxCodeType,
   @TaxParmsTaxRegNum1         TaxRegNumType,
   @TaxParmsBranchId1          BranchIdType,
   @ParmsEcReporting           ListYesNoType,
   @HdrTaxCode2                TaxCodeType,
   @TTaxIDLabel2               NVARCHAR(10),
   @TTaxRegNum2                WideTextType,
   @TaxParmsTaxRegNum2         TaxRegNumType,
   @TaxParmsBranchId2          BranchIdType,
   @CustAddrCountry            CountryType,
   @CoitemPrintKitComps        ListYesNoType,
   @PhantomFlag                ListYesNoType,
   @Component                  ItemType,
   @CompDesc                   DescriptionType,
   @CompQtyRequired            QtyUnitType,
   @CompUM                     UMType,
   @ExternalConfirmationRef    OrderConfirmationRefType,
   @AtLeastOneLine             ListYesNoType,
   @FudgeTax1                  AmountType,
   @FudgeTax2                  AmountType,
   @CoText1                    ReportTxtType,
   @CoText2                    ReportTxtType,
   @CoText3                    ReportTxtType,
   @TermLangRowPointer         RowPointerType,
   @TermLangDescription        DescriptionType,
   @ShipLangRowPointer         RowPointerType,
   @ShipLangDescription        DescriptionType,
   @CustomerLangCode           LangCodeType,
   @InvcLangRowPointer         RowPointerType,
   @InvcLangCoText##1          ReportTxtType,
   @InvcLangCoText##2          ReportTxtType,
   @InvcLangCoText##3          ReportTxtType,
   @ItemLangDescription        DescriptionType,
   @ItemLangRowPointer         RowPointerType,
   @CoDemandingSite            SiteType,
   @CoDemandingSitePoNum       PoNumType,
   @ConfigSetCount             Int,
   @SerialSetCount             Int,
   @CompOperNum                OperNumType,
   @AttrName                   ConfigAttrNameType
, @CoitemCursorCount int
, @CoitemCurrentCount int
, @AccumTax1Rounding AmountType
, @AccumTax2Rounding AmountType
, @CurrencyPriceFormat         InputMaskType
, @CurrencyPricePlaces         DecimalPlacesType
, @CurrencyFormat              InputMaskType
, @CurrencyPlaces              DecimalPlacesType
, @CurrencyTotFormat           InputMaskType
, @CurrencyTotPlaces           DecimalPlacesType
, @IntPosition                 TINYINT
, @UomConvFactor               UMConvFactorType
, @TQtyConv                    QtyUnitNoNegType

DECLARE
  @SumSurcharge             CostPrcType
, @ItemItemContent          ListYesNoType
, @TotalSurcharge           AmountType
, @ItemDrawingNumber        DrawingNbrType
, @CoItemDeliveryIncoTerm   DeltermType
, @CoItemECCode             EcCodeType
, @CoItemOriginCode         EcCodeType
, @CoItemCommodityCode      CommodityCodeType
, @ItemCustEndUser          NameType
, @DelTermDescription       DescriptionType
, @URL                      URLType
, @EmailAddr                EmailType
, @BankName                 NameType
, @BankTransitNum           BankTransitNumType
, @BankAccountNo            BankAccountType

DECLARE
   @UseAlternateAddressReportFormat   ListYesNoType

DECLARE
     @QtyUnitFormat nvarchar(30)
   , @PlacesQtyUnit tinyint

SELECT @PlacesQtyUnit = places_qty_unit,
       @QtyUnitFormat = qty_unit_format
FROM invparms

SET @QtyUnitFormat = dbo.FixMaskForCrystal( @QtyUnitFormat, dbo.GetWinRegDecGroup() )

DECLARE @ErrorLog TABLE (
   InfobarText      InfobarType,
   Severity         int
)

DECLARE @ConfigSet TABLE (
   CompOperNum      OperNumType
 , CompSequence     JobmatlSequenceType
 , CompCompName     ConfigCompNameType
 , CompQty          QtyUnitType
 , CompPrice        CostPrcType
 , AttrName         ConfigAttrNameType
 , AttrValue        ConfigAttrValueType
)

DECLARE @reportset TABLE(
   office_addr               LongAddress,
   date_appear               DateType,
   office_phone              PhoneType,
   co_num                    CoNumType,
   cust_po                   CustPoType,
   cust_num                  CustNumType,
   cust_seq                  CustSeqType,
   ship_addr                 LongAddress,
   bill_addr                 LongAddress,
   cust_fax                  PhoneType,
   curr_code                 CurrCodeType,
   curr_desc                 DescriptionType,
   contact#1                 ContactType,
   contact#2                 ContactType,
   TaxIDLabel1               NVARCHAR(10),
   TaxIDLabel2               NVARCHAR(10),
   taxreg#1                  WideTextType,
   taxreg#2                  WideTextType,
   CustBillToTaxRegNum1      WideTextType,
   CustBillToTaxRegNum2      WideTextType,
   CustShipToTaxRegNum1      WideTextType,
   CustShipToTaxRegNum2      WideTextType,
   shipdesc                  DescriptionType,
   termsdesc                 DescriptionType,
   qty_packs                 int,
   pp_flag                   NVARCHAR(3),
   order_date                DateType,
   item                      ItemType,
   cust_item                 CustItemType,
   price                     AmountType,
   net_amount                AmountType,
   co_line                   CoLineType,
   co_release                CoReleaseType,
   cast_co_release           NVARCHAR(5),
   disp_date                 DateType,
   qty_conv                  QtyUnitNoNegType,
   um                        UMType,
   item_desc                 DescriptionType,
   dropship_contact          ContactType,
   dropship_addr             NVARCHAR(400),
   serial_num                SerNumType,
   co_note_flag              ListYesNoType,
   billto_cust_note_flag     ListYesNoType,
   shipto_cust_note_flag     ListYesNoType,
   Co_bln_note_flag          ListYesNoType,
   order_disc                AmountType,
   sales_tax1                AmountType,
   sales_tax2                AmountType,
   freight                   AmountType,
   misc                      AmountType,
   prepaid                   AmountType,
   euro_total                AmountType,
   co_text1                  ReportTxtType,
   co_text2                  ReportTxtType,
   co_text3                  ReportTxtType,
   salesman                  NVARCHAR(60),
   sales                     AmountType,
   JobrouteJob               JobType,
   JobrouteSuffix            SuffixType,
   JobrouteOperNum           OperNumType,
   FeatureDisplayQty         QtyPerType,
   FeatureDisplayUM          UMType,
   FeatureDisplayDesc        DescriptionType,
   FeatureDisplayStr         FeatStrType,
   co_disc                   OrderDiscType,
   co_rowpointer             RowPointerType,
   cust_rowpointer           RowPointerType,
   Co_bln_rowpointer         RowPointerType,
   billto_cust_rowpointer    RowPointerType,
   shipto_cust_rowpointer    RowPointerType,
   site                      SiteType,
   Lcr                       LcrNumType,
   external_confirmation_ref OrderConfirmationRefType,
-- Config Columns
   HasCfgDetail              tinyint,
   CompOperNum               nVarchar(4),    -- why not int (OperNumType)?
   CompSequence              Decimal(5, 2),  -- why not smallint (JobmatlSequenceType)?
   CompCompName              ConfigCompNameType,
   CompQty                   QtyUnitType,
   CompPrice                 CostPrcType,
   AttrName                  ConfigAttrNameType,
   AttrValue                 ConfigAttrValueType,
   Co_bln_Des                DescriptionType,
   Co_item_Des               DescriptionType,
   Co_item_DesOverview       ProductOverviewType,
   Co_item_note_Flag         int,
   Co_item_Rowpointer        RowPointerType,
-- Tax
   tax_item_label1           NVARCHAR(10),
   tax_item_label2           NVARCHAR(10),
   coitem_tax_code1          TaxCodeType,
   coitem_tax_code2          TaxCodeType,
   coitem_tax_code1_desc     DescriptionType,
   coitem_tax_code2_desc     DescriptionType,
   sales_tax_label1          NVARCHAR(10),
   sales_tax_label2          NVARCHAR(10),
   TaxparmsNmbrOfSystems     TaxSystemsType,
   TaxSystemPromptOnLine1    ListYesNoType,
   TaxSystemPromptOnLine2    ListYesNoType,
   CurrencyPriceFormat       InputMaskType,
   CurrencyPricePlaces       DecimalPlacesType,
   CurrencyFormat            InputMaskType,
   CurrencyPlaces            DecimalPlacesType,
   CurrencyTotFormat         InputMaskType,
   CurrencyTotPlaces         DecimalPlacesType,
   Price_Before_Tax          AmountType,
   Include_Tax_In_Price      ListYesNoType,
-- Kit
   PrintKitonCustPaper       INT,
   Kit_Component             ItemType,
   Kit_Comp_Desc             DescriptionType,
   Kit_Qty_Required          QtyUnitType,
   Kit_U_M                   UMType,
   unique_val                int identity,
   places_qty                DecimalPlacesType,
   qty_format                InputMaskType,
   PromotionCode             PromotionCodeType,
   item_content              ListYesNoType,
-- OrderVerificationReport
   drawing_nbr               DrawingNbrType,
   delterm                   DeltermType,
   ec_code                   EcCodeType,
   origin                    EcCodeType,
   comm_code                 CommodityCodeType,
   end_user                  NameType,
   office_addr_footer        LongAddress,
   office_phone_footer       PhoneType,
   del_term_desc             DescriptionType,
   url                       URLType,
   email_addr                EmailType,
   bank_name                 NameType,
   bank_transit_num          BankTransitNumType,
   bank_acct_no              BankAccountType
 unique(co_num, co_line, co_release, unique_val)
)

DECLARE @SurchargeTable table (
     item            ItemType
   , salesman        NVARCHAR(60)
   , co_num          CoNumType
   , co_line         CoLineType
   , co_release      CoReleaseType
   , TotalSurcharge  AmountType
)

IF OBJECT_ID('tempdb..#Comp_Matl') IS NULL
   BEGIN
      SELECT
      @CoitemItem          AS Item,
      @Component           AS Component,
      @CompDesc            AS Comp_Description,
      @CompQtyRequired     AS Qty_Required,
      @CompUM              AS u_m
      INTO #Comp_Matl  --Temporary table for Phantom Item
      WHERE 1=2
   END
TRUNCATE TABLE #Comp_Matl  -- Delete data from Temporary table

declare @Sites table (
  site SiteType primary key
)
insert into @Sites select site from site

---SETS
SET @Severity               = 0
SET @TcAmtLineNet           = 0
SET @OLvlDiscLineNet        = 0
SET @TcCprPrice             = 0
SET @TcAmtDisc              = 0
SET @TcAmtPrepaid           = 0
SET @TcAmtUndisc            = 0
SET @TcAmtSalesTax          = 0
SET @TcAmtSalesTax2         = 0
SET @TcAmtSales             = 0
SET @PrintFlag              = 0
SET @TcAmtDiscount          = 0
SET @TcAmtMisc              = 0
SET @TcAmtFreight           = 0
SET @TcAmtTotal             = 0
SET @THasText               = 0
SET @PrepaidFlag            = NULL
SET @CoPrepaidAmt           = 0
SET @CoitemRowPointer       = NULL
SET @CoitemQtyOrderedConv   = 0
SET @CoitemPriceConv        = 0
SET @CoitemDisc             = 0
SET @CoitemItem             = NULL
SET @CoitemShipSite         = NULL
SET @CoitemTaxCode1         = NULL
SET @CoitemTaxCode2         = NULL
SET @CoitemTaxCode1Desc     = NULL
SET @CoitemTaxCode2Desc     = NULL
SET @CoitemCustItem         = NULL
SET @CoitemCoLine           = 0
SET @CoitemCoRelease        = 0
SET @CoitemPromiseDate      = NULL
SET @CoitemDueDate          = NULL
SET @CoitemUM               = NULL
SET @CoitemFeatStr          = NULL
SET @CoitemCustNum          = NULL
SET @CoitemCustSeq          = 0
SET @CoitemConfigId         = NULL
SET @BillToCustNoteExistsFlag     = 0
SET @ShipToCustNoteExistsFlag     = 0
SET @CoNoteExistsFlag       = 0
SET @JobrouteJob            = NULL
SET @JobrouteSuffix         = NULL
SET @JobrouteOperNum        = NULL
SET @FeatureDisplayQty      = NULL
SET @FeatureDisplayUM       = NULL
SET @FeatureDisplayDesc     = NULL
SET @FeatureDisplayStr      = NULL
SET @TEuroTotal             = 0
SET @SerialSerNum           = NULL

IF OBJECT_ID('vrtx_parm') IS NOT NULL
BEGIN
    -- Set variable to force TaxCalc to run for CO
    EXEC @Severity = dbo.DefineVariableSp
                     'SSSVTXTaxCalcForceCalc'
                   , 1
                   , @Infobar OUTPUT

    IF @Severity <> 0
    BEGIN
       EXEC dbo.CloseSessionContextSp @SessionID = @RptSessionID
       RETURN @Severity
    END
 END

EXEC dbo.ApplyDateOffsetSp
        @DateToAppear OUTPUT,
        @DateToAppearOffset,
        0

-- New tax table records
SET @SessionId = dbo.SessionIDSp()
EXEC @Severity = dbo.UseTmpTaxTablesSp @SessionId, @ReleaseTmpTaxTables OUTPUT, @Infobar OUTPUT

-- Tax Parameters
SET @TaxparmsNmbrOfSystems = 0
SELECT
  @TaxparmsNmbrOfSystems = taxparms.nmbr_of_systems
FROM taxparms

-- Get Tax System Labels / Modes
SET @TaxSystemTaxMode1      = NULL
SET @TTaxIDLabel1           = NULL
SET @TaxItemLabel1          = NULL
SET @TaxAmtLabel1           = NULL
SET @TaxSystemPromptOnLine1 = 0
SELECT
  @TaxSystemTaxMode1      = tax_system.tax_mode
, @TTaxIDLabel1           = tax_system.tax_id_label + ':'
, @TaxSystemPromptOnLine1 = tax_system.prompt_on_line
, @TaxItemLabel1          = tax_system.tax_item_label + ':'
, @TaxAmtLabel1           = tax_system.tax_amt_label + ':'
FROM tax_system
WHERE tax_system.tax_system = 1

SET @TaxSystemTaxMode2      = NULL
SET @TTaxIDLabel2           = NULL
SET @TaxItemLabel2          = NULL
SET @TaxAmtLabel2           = NULL
SET @TaxSystemPromptOnLine2 = 0
SELECT
  @TaxSystemTaxMode2      = tax_system.tax_mode
, @TTaxIDLabel2           = tax_system.tax_id_label + ':'
, @TaxSystemPromptOnLine2 = tax_system.prompt_on_line
, @TaxItemLabel2          = tax_system.tax_item_label + ':'
, @TaxAmtLabel2           = tax_system.tax_amt_label + ':'
FROM tax_system
WHERE tax_system.tax_system = 2

-- SELECTING THE USER SITE FOR REPORTING ONLY THE SITE SPECIFICATION AND TO CHECK IF THE EC REPORTING FLAG IS ON

SELECT TOP 1
 @ParmsEcReporting = parms.ec_reporting,
 @UserParmSite = parms.site
FROM parms

SELECT
    @TaxParmsTaxRegNum1 = taxparms.tax_reg_num1
   ,@TaxParmsTaxRegNum2 = taxparms.tax_reg_num2
FROM taxparms

SET @CountryEcCode = NULL

SELECT
   @CountryEcCode = country.ec_code
FROM country JOIN parms
ON parms.country = country.country

SELECT
   @CoParmsCoText1 = coparms.co_text_1,
   @CoParmsCoText2 = coparms.co_text_2,
   @CoParmsCoText3 = coparms.co_text_3,
   @CoParmsUseAltPriceCalc = coparms.use_alt_price_calc
FROM coparms

SELECT  
   @URL = parms.url 
FROM parms (READUNCOMMITTED) 
WHERE parm_key = 0

SELECT
   @EmailAddr = arparms.email_addr
FROM arparms WITH (READUNCOMMITTED)

SET @TodayDate = dbo.GetSiteDate(GETDATE())

IF @Severity = 0
   EXEC @Severity = dbo.EuroInfoSp
         0,
         @TEuroUser   OUTPUT,
         @TEuroExists OUTPUT,
         @TBaseEuro   OUTPUT,
         @TEuroCurr OUTPUT,
         @InfoBar     OUTPUT

IF @Severity <> 0
  GOTO END_OF_PROG

IF @TEuroExists = 1
BEGIN
   SELECT TOP 1
      @ECurrencyPlaces       = e_currency.places
   FROM currency_ALL  AS e_currency
   WHERE e_currency.Site_ref = @UserParmSite
     AND e_currency.curr_code = @TEuroCurr
   ORDER BY e_currency.curr_code ASC
END

SELECT @UseAlternateAddressReportFormat = use_alt_addr_report_formatting FROM parms WITH (readuncommitted) WHERE parm_key = 0

IF  @PrintCompanyName = 1
  BEGIN
    IF @UseAlternateAddressReportFormat = 0
     BEGIN
       SET @OfficeAddr = dbo.DisplayOurAddress()
       SELECT @OfficePhone = parms_all.phone
       FROM parms_all
       where parms_all.site_ref = @UserParmSite
     END
    ELSE
      SET @OfficeAddr = dbo.GetParmsSingleLineAddressSp()
      
    SET @OfficeAddrFooter = dbo.DisplayAddressForReportFooter()
    SELECT @OfficePhoneFooter = parms_all.phone FROM parms_all WHERE parms_all.site_ref = @UserParmSite
  END  
ELSE
   BEGIN
      SET @OfficeAddr = NULL
      SET @OfficeAddrFooter = NULL
      SET @OfficePhoneFooter = NULL
   END

DECLARE CoAllCrs CURSOR LOCAL STATIC FOR
SELECT
   co_all.RowPointer,
   co_all.co_num,
   co_all.slsman,
   co_all.cust_po,
   co_all.lcr_num,
   co_all.cust_num,
   co_all.cust_seq,
   co_all.qty_packages,
   co_all.order_date,
   co_all.prepaid_amt,
   co_all.misc_charges,
   co_all.m_charges_t,
   co_all.freight,
   co_all.freight_t,
   co_all.tax_code1,
   co_all.tax_code2,
   co_all.frt_tax_code1,
   co_all.frt_tax_code2,
   co_all.msc_tax_code1,
   co_all.msc_tax_code2,
   co_all.terms_code,
   co_all.use_exch_rate,
   co_all.exch_rate,
   co_all.prepaid_t,
   co_all.orig_site,
   co_all.type,
   co_all.disc,
   co_all.disc_amount
, co_all.discount_type
, (select sum(all_sites_co.price) from co_all as all_sites_co
         where all_sites_co.co_num = co_all.co_num
         and all_sites_co.site_ref in (select site from @Sites))
      - co_all.sales_tax - co_all.sales_tax_2 - co_all.misc_charges - co_all.freight
      - co_all.sales_tax_t - co_all.sales_tax_t2 - co_all.m_charges_t - co_all.freight_t
, terms.description
, co.ship_code
, shipcode.description
, co.contact
, co.include_tax_in_price
, co.external_confirmation_ref
, BillTo.RowPointer
, ShipTo.edi_cust
, BillTo.cust_num
, BillTo.cust_seq
, BillTo.cust_type
, BillTo.tax_code1
, BillTo.tax_code2
, BillTo.lang_code
, custaddr.country
, custaddr.RowPointer
, custaddr.curr_code
, custaddr.fax_num
, currency.description
, isnull(currency.places, 0)
, ShipTo.contact##2
, slsman_all.RowPointer
, isnull(slsman_all.outside, 0)
, slsman_all.ref_num
, slsman_all.slsman
, term_lang.RowPointer
, term_lang.description
, ship_lang.RowPointer
, ship_lang.description
, invc_lang.RowPointer
, invc_lang.co_text##1
, invc_lang.co_text##2
, invc_lang.co_text##3
, co.demanding_site
, co.demanding_site_po_num
, currency.amt_format
, currency.amt_tot_format
, currency.cst_prc_format
, currency.places_cp
, bank_hdr.name       
, bank_hdr.bank_transit_num
, BillTo.bank_acct_no
FROM co_all
   left outer join terms on
      terms.terms_code = co_all.terms_code
   left outer join co on
      co.co_num = co_all.co_num
   left outer join shipcode on
      shipcode.ship_code = co.ship_code
   left outer join customer as BillTo on
      BillTo.cust_num = co_all.cust_num
      and BillTo.cust_seq = 0
   left outer join custaddr on
      custaddr.cust_num = co_all.cust_num
      and custaddr.cust_seq = 0
   left outer join currency on
      currency.curr_code = custaddr.curr_code
   left outer join customer as ShipTo on
      ShipTo.cust_num = co_all.cust_num
      and ShipTo.cust_seq = co_all.cust_seq
   left outer join slsman_all on
      slsman_all.slsman = co.slsman
      and slsman_all.site_ref = co_all.site_ref
   left outer join term_lang on
      term_lang.terms_code = terms.terms_code
      and term_lang.lang_code = BillTo.lang_code
   left outer join ship_lang on
      ship_lang.ship_code = shipcode.ship_code
      and ship_lang.lang_code = BillTo.lang_code
   left outer join invc_lang on
      invc_lang.lang_code = BillTo.lang_code
   left outer join bank_hdr on
      BillTo.cust_bank = bank_hdr.bank_code

WHERE co_all.site_ref = @UserParmSite
  AND ((co_all.type = 'R' and @CoTypeRegular = 1) or (co_all.type = 'B' and @CoTypeBlanket = 1))
  AND CHARINDEX(co_all.stat, 'PO') <> 0
  AND (co_all.co_num >= @OrderStarting AND co_all.co_num <= @OrderEnding)
  AND (ISNULL(co_all.slsman, dbo.LowCharacter()) BETWEEN @SalespersonStarting AND @SalespersonEnding)
  AND co.demanding_site_po_num IS NULL

UNION

SELECT
   co_all.RowPointer,
   co_all.co_num,
   co_all.slsman,
   co_all.cust_po,
   co_all.lcr_num,
   co_all.cust_num,
   co_all.cust_seq,
   co_all.qty_packages,
   co_all.order_date,
   co_all.prepaid_amt,
   co_all.misc_charges,
   co_all.m_charges_t,
   co_all.freight,
   co_all.freight_t,
   co_all.tax_code1,
   co_all.tax_code2,
   co_all.frt_tax_code1,
   co_all.frt_tax_code2,
   co_all.msc_tax_code1,
   co_all.msc_tax_code2,
   co_all.terms_code,
   co_all.use_exch_rate,
   co_all.exch_rate,
   co_all.prepaid_t,
   co_all.orig_site,
   co_all.type,
   co_all.disc,
   co_all.disc_amount
, co_all.discount_type
, (select sum(all_sites_co.price) from co_all as all_sites_co
         where all_sites_co.co_num = co_all.co_num
         and all_sites_co.site_ref in (select site from @Sites))
      - co_all.sales_tax - co_all.sales_tax_2 - co_all.misc_charges - co_all.freight
      - co_all.sales_tax_t - co_all.sales_tax_t2 - co_all.m_charges_t - co_all.freight_t
, terms.description
, co.ship_code
, shipcode.description
, co.contact
, co.include_tax_in_price
, co.external_confirmation_ref
, BillTo.RowPointer
, BillTo.edi_cust
, BillTo.cust_num
, BillTo.cust_seq
, BillTo.cust_type
, BillTo.tax_code1
, BillTo.tax_code2
, BillTo.lang_code
, custaddr.country
, custaddr.RowPointer
, custaddr.curr_code
, custaddr.fax_num
, currency.description
, isnull(currency.places, 0)
, ShipTo.contact##2
, slsman_all.RowPointer
, isnull(slsman_all.outside, 0)
, slsman_all.ref_num
, slsman_all.slsman
, term_lang.RowPointer
, term_lang.description
, ship_lang.RowPointer
, ship_lang.description
, invc_lang.RowPointer
, invc_lang.co_text##1
, invc_lang.co_text##2
, invc_lang.co_text##3
, co.demanding_site
, co.demanding_site_po_num
, currency.amt_format
, currency.amt_tot_format
, currency.cst_prc_format
, currency.places_cp
, bank_hdr.name       
, bank_hdr.bank_transit_num
, BillTo.bank_acct_no
FROM co_all
   left outer join terms on
      terms.terms_code = co_all.terms_code
   left outer join co on
      co.co_num = co_all.co_num
   left outer join shipcode on
      shipcode.ship_code = co.ship_code
   left outer join customer as BillTo on
      BillTo.cust_num = co_all.cust_num
      and BillTo.cust_seq = 0
   left outer join custaddr on
      custaddr.cust_num = co_all.cust_num
      and custaddr.cust_seq = 0
   left outer join currency on
      currency.curr_code = custaddr.curr_code
   left outer join customer_all as ShipTo on
      ShipTo.cust_num = co_all.cust_num AND co.demanding_site = ShipTo.site_ref
      and ShipTo.cust_seq = co_all.cust_seq
   left outer join slsman_all on
      slsman_all.slsman = co.slsman
      and slsman_all.site_ref = co_all.site_ref
   left outer join term_lang on
      term_lang.terms_code = terms.terms_code
      and term_lang.lang_code = BillTo.lang_code
   left outer join ship_lang on
      ship_lang.ship_code = shipcode.ship_code
      and ship_lang.lang_code = BillTo.lang_code
   left outer join invc_lang on
      invc_lang.lang_code = BillTo.lang_code
   left outer join bank_hdr on
      BillTo.cust_bank = bank_hdr.bank_code

WHERE co_all.site_ref = @UserParmSite
  AND ((co_all.type = 'R' and @CoTypeRegular = 1) or (co_all.type = 'B' and @CoTypeBlanket = 1))
  AND CHARINDEX(co_all.stat, 'PO') <> 0
  AND (co_all.co_num >= @OrderStarting AND co_all.co_num <= @OrderEnding)
  AND (ISNULL(co_all.slsman, dbo.LowCharacter()) BETWEEN @SalespersonStarting AND @SalespersonEnding)
  AND co.demanding_site_po_num IS NOT NULL


OPEN CoAllCrs
WHILE @Severity = 0
BEGIN
   FETCH CoAllCrs INTO
      @CoRowPointer,
      @CoCoNum,
      @CoSlsman,
      @CoCustPo,
      @CoLcrNum,
      @CoCustNum,
      @CoCustSeq,
      @CoQtyPackages,
      @CoOrderDate,
      @CoPrepaidAmt,
      @CoMiscCharges,
      @CoMChargesT,
      @CoFreight,
      @CoFreightT,
      @CoTaxCode1,
      @CoTaxCode2,
      @CoFrtTaxCode1,
      @CoFrtTaxCode2,
      @CoMscTaxCode1,
      @CoMscTaxCode2,
      @CoTermsCode,
      @CoUseExchRate,
      @CoExchRate,
      @CoPrepaidT,
      @CoOrigSite,
      @CoType,
      @CoDisc
   , @CoDiscAmount
   , @CoDiscountType
   , @TcAmtLineNet
   , @TermsDescription
   , @CoShipCode
   , @ShipcodeDescription
   , @CustomerContact1
   , @IncludeTaxInPrice
   , @ExternalConfirmationRef
   , @CustomerRowPointer
   , @CustomerEdiCust
   , @CustomerCustNum
   , @CustomerCustSeq
   , @CustomerCustType
   , @HdrTaxCode1
   , @HdrTaxCode2
   , @CustomerLangCode
   , @CustAddrCountry
   , @CustaddrRowPointer
   , @CustaddrCurrCode
   , @CustaddrFaxNum
   , @CurrencyDescription
   , @CurrencyPlaces
   , @CustomerContact2
   , @SlsmanRowPointer
   , @SlsmanOutside
   , @SlsmanRefNum
   , @SlsmanSlsman
   , @TermLangRowPointer
   , @TermLangDescription
   , @ShipLangRowPointer
   , @ShipLangDescription
   , @InvcLangRowPointer
   , @InvcLangCoText##1
   , @InvcLangCoText##2
   , @InvcLangCoText##3
   , @CoDemandingSite
   , @CoDemandingSitePoNum
   , @CurrencyFormat
   , @CurrencyTotFormat
   , @CurrencyPriceFormat
   , @CurrencyPricePlaces
   , @BankName       
   , @BankTransitNum 
   , @BankAccountNo  

   IF @@FETCH_STATUS = -1
      BREAK

   if @CoDiscountType = 'A'
   begin
      if @CoDiscAmount = 0
      or @TcAmtLineNet = 0
         set @CoDisc = 0
      else
         set @CoDisc = (@CoDiscAmount * 100.0) / (@TcAmtLineNet + @CoDiscAmount)
   end
   set @TcAmtLineNet = 0

   IF @CoPrepaidAmt <> 0.0
      SET @PrepaidFlag = 'Y'
   ELSE
      SET @PrepaidFlag = ''

   SET @TTaxRegNum1 = NULL
   SET @TCustBillToTaxRegNum1 = NULL
   SET @TCustShipToTaxRegNum1 = NULL

   -- POPULATES THE VALUE FOR FED ID 1
   EXEC @Severity         = dbo.TaxIdSp
        @pTaxSystem       = 1
      , @pTaxCode         = @HdrTaxCode1
      , @pBranchDefined   = 1
      , @pCustAddrCountry = @CustAddrCountry
      , @CustNum          = @CoCustNum
      , @rTaxRegNum       = @TTaxRegNum1 OUTPUT
      , @rCustRegNum      = @TCustBillToTaxRegNum1 OUTPUT
      , @Infobar          = @Infobar OUTPUT
      , @CustSeq          = @CoCustSeq
      , @CustShipToRegNum = @TCustShipToTaxRegNum1 OUTPUT

   IF @Severity <> 0
   BEGIN
     INSERT INTO @ErrorLog
      (InfobarText, severity)
     VALUES
      (@Infobar,@Severity  )
         SET @Severity = 0
   END

   SET @TTaxRegNum2 = NULL
   SET @TCustBillToTaxRegNum2 = NULL
   SET @TCustShipToTaxRegNum2 = NULL

   -- POPULATES THE VALUE FOR FED ID 2
   EXEC @Severity         = dbo.TaxIdSp
        @pTaxSystem       = 2
      , @pTaxCode         = @HdrTaxCode2
      , @pBranchDefined   = 0
      , @pCustAddrCountry = @CustAddrCountry
      , @CustNum          = @CoCustNum
      , @rTaxRegNum       = @TTaxRegNum2 OUTPUT
      , @rCustRegNum      = @TCustBillToTaxRegNum2 OUTPUT
      , @Infobar          = @Infobar OUTPUT
      , @CustSeq          = @CoCustSeq
      , @CustShipToRegNum = @TCustShipToTaxRegNum2 OUTPUT

   IF @Severity <> 0
   BEGIN
     INSERT INTO @ErrorLog
      (InfobarText, severity)
     VALUES
      (@Infobar,@Severity  )
         SET @Severity = 0
   END

   IF @CustomerRowPointer IS NOT NULL AND @CustomerEdiCust = 1
   BEGIN
      SET @PrintFlag = 1
      EXEC @Severity = dbo.EdiOutObDriverSp
        @PTranType = 'ACK'
      , @PCustNum = @CoCustNum
      , @PCustSeq = @CoCustSeq
      , @PInvNum = '0'
      , @PCoNum = @CoCoNum
      , @PBolNum = NULL
      , @PFlag = @PrintFlag OUTPUT
      , @Infobar = @Infobar OUTPUT

      IF @Severity <> 0
      BEGIN
         INSERT INTO @ErrorLog (
            InfobarText,
            severity
         )
         VALUES (
            @Infobar,
            @Severity
         )
         SET @Severity = 0
      END

      IF @PrintFlag = 0
         CONTINUE
   END -- EDI

--   SET @BillTo = dbo.FormatAddressWithContactSp ( @CoCustNum, 0, @CustomerContact1)
--   SET @ShipTo = dbo.FormatAddressWithContactSp ( @CoCustNum, @CoCustSeq, @CustomerContact2)

   SET @BillTo = dbo.FormatAddress( @CoCustNum, 0)
   SET @ShipTo = dbo.FormatAddress ( @CoCustNum, @CoCustSeq)

      /* Try to find Salesperson, ELSE print Salesperson code. */
   SET @TSlsman = @CoSlsman
   IF @SlsmanRowPointer IS NOT NULL AND @SlsmanOutside = 1
   BEGIN
      SET @VendaddrRowPointer = NULL
      SET @VendaddrName       = NULL

      SELECT
         @VendaddrRowPointer = vendaddr.RowPointer,
         @VendaddrName       = vendaddr.name
      FROM vendaddr
      WHERE vendaddr.vend_num = @SlsmanRefNum
      IF @VendaddrRowPointer IS NOT NULL
         SET @TSlsman = @VendaddrName
   END
   ELSE
   BEGIN
      SET @EmployeeRowPointer = NULL
      SET @EmployeeName       = NULL

      SELECT
         @EmployeeRowPointer = employee.RowPointer,
         @EmployeeName       = dbo.GetEmployeeName(employee.emp_num)
      FROM employee
      WHERE employee.emp_num = @SlsmanRefNum

      IF @EmployeeRowPointer IS NOT NULL
         SET @TSlsman = @EmployeeName
   END

   set @TEuroTotal = 0
   SET @TcAmtMisc = @CoMiscCharges + @CoMChargesT
   SET @TcAmtFreight = @CoFreight + @CoFreightT
   SET @TcAmtMisc2 = @CoMiscCharges + @CoMChargesT
   SET @TcAmtFreight2 = @CoFreight + @CoFreightT

   set @AtLeastOneLine = 0
   set @FudgeTax1 = 0
   set @FudgeTax2 = 0

   exec dbo.UseTmpTaxTablesSp
     @PSessionId = @SessionId
   , @LocalInit  = null
   , @Infobar    = @Infobar OUTPUT

   -- LOOKING FOR MULTI-LINGUAL
   SET @TermsDescription = CASE  WHEN @TermLangRowPointer IS NOT NULL
           THEN @TermLangDescription
         ELSE @TermsDescription
         END

   SET @ShipcodeDescription = CASE  WHEN @ShipLangRowPointer IS NOT NULL
                                    THEN @ShipLangDescription
                                    ELSE @ShipcodeDescription
                              END
   SET @CoText1 = CASE  WHEN @InvcLangRowPointer IS NOT NULL
                        THEN @InvcLangCoText##1
                        ELSE @CoParmsCoText1
                  END
   SET @CoText2 = CASE  WHEN @InvcLangRowPointer IS NOT NULL
                        THEN @InvcLangCoText##2
                        ELSE @CoParmsCoText2
                  END
   SET @CoText3 = CASE  WHEN @InvcLangRowPointer IS NOT NULL
                        THEN @InvcLangCoText##3
                        ELSE @CoParmsCoText3
                  END

--PRINT CO HEADER TEXT
   IF  @PrintOrderText = 1
   BEGIN
    SELECT
       @CoNoteExistsFlag = dbo.ReportNotesExist('co', co_all.RowPointer, @ShowInternal, @ShowExternal,
           co_all.NoteExistsFlag)
    FROM co_all
    WHERE co_all.RowPointer = @CoRowPointer
   END

   SET @THasText = 0

   IF @PrintBillToNotes = 1
   BEGIN
    SET @BillToCustomerRowPointer = NULL
    SET @CustomerLcrReqd = 0
    SET @CustomerCustNum = NULL
    SET @BillToCustNoteExistsFlag = NULL
    SELECT
       @BillToCustomerRowPointer = customer.RowPointer,
       @BillToCustNoteExistsFlag = dbo.ReportNotesExist('Customer', customer.RowPointer, @ShowInternal, @ShowExternal,
          customer.NoteExistsFlag),
       @CustomerLcrReqd = customer.lcr_reqd,
       @CustomerCustNum = customer.cust_num
    FROM customer
    WHERE customer.cust_num = @CoCustNum
      AND customer.cust_seq = 0

    IF @BillToCustNoteExistsFlag IS NOT NULL
       SET @THasText = 1
   END

   IF @PrintShiptoNotes = 1 -- Ship To
   BEGIN
    SET @ShipToCustomerRowPointer = NULL
    SET @CustomerLcrReqd = 0
    SET @CustomerCustNum = NULL
    SET @ShipToCustNoteExistsFlag = NULL
    IF @CoDemandingSitePoNum IS NULL
    BEGIN
     SELECT
       @ShipToCustomerRowPointer = customer.RowPointer,
       @ShipToCustNoteExistsFlag = dbo.ReportNotesExist('Customer', customer.RowPointer, @ShowInternal, @ShowExternal,
             customer.NoteExistsFlag),
       @CustomerLcrReqd = customer.lcr_reqd,
       @CustomerCustNum = customer.cust_num
     FROM  customer
     WHERE customer.cust_num = @CoCustNum
       AND customer.cust_seq = @CoCustSeq
    END
    ELSE
    BEGIN
     SELECT
       @ShipToCustomerRowPointer = customer.RowPointer,
       @ShipToCustNoteExistsFlag = dbo.ReportNotesExist('Customer', customer.RowPointer, @ShowInternal, @ShowExternal,
             customer.NoteExistsFlag),
       @CustomerLcrReqd = customer.lcr_reqd,
       @CustomerCustNum = customer.cust_num
     FROM  customer_all AS customer
     WHERE customer.cust_num = @CoCustNum
       AND customer.cust_seq = @CoCustSeq
       AND customer.site_ref = @CoDemandingSite
    END
    IF @ShipToCustNoteExistsFlag IS NOT NULL
       SET @THasText = 1
   END

   if @CoType = 'R'
      DECLARE CoItemAllCrs CURSOR LOCAL STATIC FOR
      SELECT
         coitem_all.RowPointer,
         coitem_all.qty_ordered_conv,
         coitem_all.price_conv,
         coitem_all.disc,
         coitem_all.item,
         coitem_all.ship_site,
         coitem_all.tax_code1,
         coitem_all.tax_code2,
         coitem_all.cust_item,
         coitem_all.co_line,
         coitem_all.co_release,
         coitem_all.promise_date,
         coitem_all.due_date,
         coitem_all.u_m,
         coitem_all.feat_str,
         coitem_all.cust_num,
         coitem_all.cust_seq,
         coitem_all.NoteExistsFlag,
         coitem_all.description,
         CASE WHEN @PrintItemOverview = 1
              THEN ISNULL(LEFT(item_lang.overview, 100), LEFT(item.overview, 100))
              ELSE NULL
         END,
         coitem.print_kit_components,
         item_lang.description,
         item_lang.RowPointer,
         coitem_all.promotion_code,
         item.item_content,
         item.drawing_nbr,
         coitem_all.delterm,
         coitem_all.ec_code,
         coitem_all.origin,
         coitem_all.comm_code,
         itemcust.end_user,
         del_term.description
      FROM coitem_all
      INNER JOIN coitem ON coitem.co_line =  coitem_all.co_line
      LEFT JOIN item ON item.item = coitem_all.item
      LEFT JOIN itemcust ON itemcust.cust_item = coitem_all.cust_item AND itemcust.item = coitem_all.item AND itemcust.cust_num = coitem_all.co_cust_num
      LEFT JOIN del_term ON del_term.delterm = coitem_all.delterm
      LEFT OUTER JOIN item_lang on item_lang.item = coitem_all.item
                               and item_lang.lang_code = @CustomerLangCode
      WHERE coitem_all.co_num = @CoCoNum
        AND coitem_all.site_ref = @UserParmSite
        AND CHARINDEX( coitem_all.stat,  @CoLineReleaseStat) > 0
        AND (coitem_all.co_line >= @OrderLineStarting AND coitem_all.co_line <= @OrderLineEnding)
        AND (coitem_all.co_release >= @OrderReleaseStarting AND coitem_all.co_release <= @OrderReleaseEnding)
        AND coitem.co_line = coitem_all.co_line
        AND coitem.co_release = coitem_all.co_release
        AND coitem.co_num = coitem_all.co_num
   else
      DECLARE CoItemAllCrs CURSOR LOCAL STATIC FOR
      SELECT
         coitem_all.RowPointer,
         coitem_all.qty_ordered_conv,
         coitem_all.price_conv,
         coitem_all.disc,
         coitem_all.item,
         coitem_all.ship_site,
         coitem_all.tax_code1,
         coitem_all.tax_code2,
         coitem_all.cust_item,
         coitem_all.co_line,
         coitem_all.co_release,
         coitem_all.promise_date,
         coitem_all.due_date,
         coitem_all.u_m,
         coitem_all.feat_str,
         coitem_all.cust_num,
         coitem_all.cust_seq,
         coitem_all.NoteExistsFlag,
         coitem_all.description,
         CASE WHEN @PrintItemOverview = 1
              THEN ISNULL(LEFT(item_lang.overview, 100), LEFT(item.overview, 100))
              ELSE NULL
         END,
         co_bln.print_kit_components,
         item_lang.description,
         item_lang.RowPointer,
         coitem_all.promotion_code,
         item.item_content,
         item.drawing_nbr,
         coitem_all.delterm,
         coitem_all.ec_code,
         coitem_all.origin,
         coitem_all.comm_code,
         itemcust.end_user,
         del_term.description
      FROM coitem_all
      INNER JOIN co_bln ON co_bln.co_line =  coitem_all.co_line
      LEFT JOIN item ON item.item = coitem_all.item
      LEFT JOIN itemcust ON itemcust.cust_item = coitem_all.cust_item AND itemcust.item = coitem_all.item AND itemcust.cust_num = coitem_all.co_cust_num
      LEFT JOIN del_term ON del_term.delterm = coitem_all.delterm
      LEFT OUTER JOIN item_lang on item_lang.item = coitem_all.item
                               and item_lang.lang_code = @CustomerLangCode
      WHERE coitem_all.co_num = @CoCoNum
        AND coitem_all.site_ref = @UserParmSite
        AND CHARINDEX( coitem_all.stat,  @CoLineReleaseStat) > 0
        AND (coitem_all.co_line >= @OrderLineStarting AND coitem_all.co_line <= @OrderLineEnding)
        AND (coitem_all.co_release >= @OrderReleaseStarting AND coitem_all.co_release <= @OrderReleaseEnding)
        AND co_bln.co_line = coitem_all.co_line
        AND co_bln.co_num = coitem_all.co_num

   OPEN CoItemAllCrs
   set @CoitemCursorCount = @@cursor_rows
   set @CoitemCurrentCount = 0
   set @AccumTax1Rounding = 0
   set @AccumTax2Rounding = 0
   WHILE @Severity = 0
   BEGIN
      FETCH CoItemAllCrs INTO
         @CoitemRowPointer,
         @CoitemQtyOrderedConv,
         @CoitemPriceConv,
         @CoitemDisc,
         @CoitemItem,
         @CoitemShipSite,
         @CoitemTaxCode1,
         @CoitemTaxCode2,
         @CoitemCustItem,
         @CoitemCoLine,
         @CoitemCoRelease,
         @CoitemPromiseDate,
         @CoitemDueDate,
         @CoitemUM,
         @CoitemFeatStr,
         @CoitemCustNum,
         @CoitemCustSeq,
         @coitemNoteExistsFlag,
         @coitemDescription,
         @coitemDescriptionOverview,
         @CoitemPrintKitComps,
         @ItemLangDescription,
         @ItemLangRowPointer,
         @PromotionCode,
         @ItemItemContent,
         @ItemDrawingNumber,     
         @CoItemDeliveryIncoTerm,
         @CoItemECCode,        
         @CoItemOriginCode,
         @CoItemCommodityCode,
         @ItemCustEndUser,
         @DelTermDescription

      IF @CoitemCoRelease = 0
         SET @CastCoitemCoRelease = NULL
      ELSE
      begin
         SET @CastCoitemCoRelease = CAST (@CoitemCoRelease as NVARCHAR(4))
         SET @CastCoitemCoRelease = '-' + space(4 - len(@CastCoitemCoRelease)) + CAST (@CoitemCoRelease as NVARCHAR(4))
      end

      IF @@FETCH_STATUS = -1
         BREAK

      set @AtLeastOneLine = 1
      SET @CusttypeRowPointer   = NULL
      SET @CusttypeTaxablePrice = NULL
      set @CoitemCurrentCount = @CoitemCurrentCount + 1

      SELECT
         @CusttypeRowPointer   = custtype.RowPointer,
         @CusttypeTaxablePrice = custtype.taxable_price
      FROM custtype
      where custtype.cust_type = @CustomerCustType

      IF @CoRowPointer IS NULL OR @CoitemRowPointer IS NULL
        OR @CustomerRowPointer IS NULL OR @CustaddrRowPointer IS NULL
         GOTO EXIT_SP

      IF @CoParmsUseAltPriceCalc = 1
         SET @TcAmtLineNet = ROUND((@CoitemPriceConv * (1.0 - @CoitemDisc / 100.0)), @CurrencyPlaces) * @CoitemQtyOrderedConv
      ELSE
         SET @TcAmtLineNet = ROUND(@CoitemQtyOrderedConv * (@CoitemPriceConv * (1.0 - @CoitemDisc / 100.0)),
                                   @CurrencyPlaces)

      SET @TcCprPrice   = @CoitemPriceConv * (1.0 - @CoitemDisc / 100.0)
      SET @TcAmtDisc    = @CoitemDisc
      SET @TcAmtUndisc  = ROUND(@CoitemQtyOrderedConv * @CoitemPriceConv, @CurrencyPlaces)

      SET @ItemUWsPrice   = 0
      SET @ItemDescription= @coitemDescription

      SELECT
         @ItemUWsPrice       = item.u_ws_price,
         @ItemDescription    = item.description
      FROM item
      WHERE item.item = @CoitemItem

   -- LOOKING FOR MULTI-LINGUAL
      SET @coitemDescription =  CASE  WHEN @ItemLangRowPointer IS NOT NULL
                          THEN @ItemLangDescription
                          ELSE @coitemDescription
              END
     

         --ACCUMULATE TAXABLES FOR THIS LINE ITEM
      SET @OLvlDiscLineNet = ROUND(@TcAmtLineNet * (1.0 - @CoDisc / 100.0),@CurrencyPlaces)

      IF @CusttypeRowPointer IS NULL
         SET @CusttypeTaxablePrice = 'W'

      SET @TcAmtSales = @TcAmtSales + @TcAmtLineNet

      IF @IncludeTaxInPrice = 1
      BEGIN
           EXEC @Severity = dbo.TaxPriceSeparationSp
                @InvType                = 'R'
              , @Type                   = 'I'
              , @TaxCode1               = @CoitemTaxCode1
              , @TaxCode2               = @CoitemTaxCode2
              , @HdrTaxCode1            = @CoTaxCode1
              , @HdrTaxCode2            = @CoTaxCode2

              , @Amount                 = @OLvlDiscLineNet
              , @UndiscAmount           = @TcAmtUndisc

              , @CurrCode               = @CustaddrCurrCode
              , @ExchRate               = @CoExchRate
              , @UseExchRate            = @CoUseExchRate
              , @Places                 = 8
              , @InvDate                = @TodayDate
              , @TermsCode              = @CoTermsCode

              , @AmountWithoutTax       = @OLvlDiscLineNet OUTPUT
              , @UndiscAmountWithoutTax = @TcAmtUndisc     OUTPUT
              , @Tax1OnAmount           = @xAmount         OUTPUT
              , @Tax2OnAmount           = @xAmount         OUTPUT
              , @Tax1OnUndiscAmount     = @xAmount         OUTPUT
              , @Tax2OnUndiscAmount     = @xAmount         OUTPUT
              , @Infobar                = @Infobar         OUTPUT
              , @Site = @CoitemShipSite

               IF @Severity <> 0
                   GOTO END_OF_PROG

          SET @PriceBeforeTax = @OLvlDiscLineNet

      END -- IF @IncludeTaxInPrice = 1

      EXEC @Severity = dbo.TaxBaseSp
                  'R',                    -- p-inv-type = Regular
                  'I',                    -- F Freight, M Misc chgs, I Line Items
                  @CoitemTaxCode1,        -- p-tax-code1
                  @CoitemTaxCode2,        -- p-tax-code2
                  @OLvlDiscLineNet,       -- p-amount
                  0,                      -- p-amount-to-apply
                  @TcAmtUndisc,           -- p-undisc-amount
                  @ItemUWsPrice,          --p-u-ws-price
                  @CusttypeTaxablePrice,  -- p-taxable-price,
                  @CoitemQtyOrderedConv,
                  @CustaddrCurrCode,      --p-curr-code
                  @TodayDate,             -- p-inv-date, ? = use today
                  @CoExchRate,   --p-exch-rate
                  @Infobar OUTPUT,
                  @pRefType       = 'O',
                 @pHdrPtr        = @CoRowPointer,
                 @pLineRefType   = null,
                 @pLinePtr       = @CoitemRowPointer
      , @Site = @CoitemShipSite

      IF @Severity <> 0
         GOTO END_OF_PROG

      IF @TEuroExists = 1
      BEGIN
         EXEC @Severity = dbo.EuroPartSp
                @CustaddrCurrCode,
                @PPartOfEuro OUTPUT
         IF @PPartOfEuro = 1
         BEGIN
            SET @EuroConvAmount  = dbo.EuroCnvt (@TcAmtLineNet,@CustaddrCurrCode,0,1)
            SET @TEuroTotal = ROUND (@TEuroTotal + @EuroConvAmount, @ECurrencyPlaces)
         END
      END

--         PROCEDURE calc-all-charges

-- PRINT BLANKET LINE TEXT --
      set @Co_bln_Des = null
      set @Co_blnRowPointer = null
      set @Co_blnNoteExistsFlag = 0
      if @CoType = 'B'
      begin
         IF @PrintBlanketLineText = 1
         BEGIN
            SELECT

               @Co_blnRowPointer = co_bln_all.RowPointer,
               @Co_blnNoteExistsFlag = dbo.ReportNotesExist('co_bln', co_bln_all.RowPointer, @ShowInternal, @ShowExternal,
                  co_bln_all.NoteExistsFlag)
            FROM co_bln_all
            WHERE co_bln_all.co_num = @CoCoNum
              AND co_bln_all.co_line = @CoitemCoLine
              and co_bln_all.site_ref = @UserParmSite

         END
-- PRINT BLANKET LINE Description --
         IF @PrintBlanketLineDes = 1
         BEGIN

            SELECT @Co_bln_Des = co_bln.Description
            FROM co_bln
            WHERE co_bln.co_num = @CoCoNum
              AND co_bln.co_line = @CoitemCoLine

         END
      end
--PRINT LINE RELEASE
      IF @PrintLineReleaseNotes=1
         BEGIN
            SELECT
               @Coitem_allNoteExistsFlag = dbo.ReportNotesExist('coitem', @coitemRowPointer, @ShowInternal, @ShowExternal,
                   coitem.NoteExistsFlag)
            FROM coitem
            WHERE coitem.co_num = @CoCoNum
              AND coitem.co_line = @CoitemCoLine
              AND coitem.co_release = @CoitemCoRelease
         END

      IF @PrintLineReleaseDes=0
         SET @coitemDescription = NULL

      -- KIT
      IF @CoitemPrintKitComps = 1
      BEGIN
         TRUNCATE TABLE #Comp_Matl
         EXEC dbo.GetKitItemBOMSp @CoitemItem,@CoitemItem,@CoitemQtyOrderedConv,1

         INSERT INTO @reportset (
            co_num, co_line, co_release, cast_co_release, item, site, salesman,
            co_note_flag, billto_cust_note_flag,
            shipto_cust_note_flag, co_rowpointer, cust_rowpointer,
            billto_cust_rowpointer, shipto_cust_rowpointer, PrintKitonCustPaper,
            Kit_Component, Kit_Comp_Desc, Kit_Qty_Required, Kit_U_M
            , places_qty, qty_format
            )
         SELECT
           @CoCoNum, @CoitemCoLine, @CoitemCoRelease, @CastCoitemCoRelease, @CoitemItem, @UserParmSite, @TSlsman
         , @CoNoteExistsFlag, @BillToCustNoteExistsFlag
         , @ShipToCustNoteExistsFlag, @CoRowPointer, @CustomerRowPointer
         , @BillToCustomerRowPointer, @ShipToCustomerRowPointer, @CoitemPrintKitComps
         , #comp_matl.Component, #comp_matl.Comp_Description, #comp_matl.Qty_Required, #comp_matl.u_m
         , @PlacesQtyUnit, @QtyUnitFormat 
         FROM #comp_matl
      END
      
      -- PRINT FBOM STUFF
      IF  @PrintPlanningItemMaterials = 1 AND @CoitemFeatStr IS NOT NULL
      BEGIN
         INSERT INTO @reportset (
            co_num,co_line,co_release,cast_co_release,item,site,salesman,
            JobrouteJob,JobrouteSuffix,JobrouteOperNum,
            FeatureDisplayQty,FeatureDisplayUM,FeatureDisplayDesc,
            FeatureDisplayStr,co_note_flag,billto_cust_note_flag,
            shipto_cust_note_flag,co_rowpointer,cust_rowpointer,
            billto_cust_rowpointer,shipto_cust_rowpointer,PrintKitonCustPaper,PromotionCode,item_content,
            drawing_nbr,delterm,ec_code,origin,comm_code,end_user,del_term_desc
            )
         SELECT
            @CoCoNum,@CoitemCoLine,@CoitemCoRelease,@CastCoitemCoRelease,@CoitemItem,@UserParmSite,@TSlsman
            , dconfig.JobRouteJob, dconfig.JobrouteSuffix, dconfig.JobrouteOperNum
            , dconfig.FeatureDisplayQty, dconfig.FeatureDisplayUM, dconfig.FeatureDisplayDesc
            , SUBSTRING(dconfig.FeatureDisplayStr,1,40), @CoNoteExistsFlag, @BillToCustNoteExistsFlag
            , @ShipToCustNoteExistsFlag, @CoRowPointer,@CustomerRowPointer
            , @BillToCustomerRowPointer, @ShipToCustomerRowPointer,@CoitemPrintKitComps,@PromotionCode,@ItemItemContent
            , @ItemDrawingNumber, @CoItemDeliveryIncoTerm, @CoItemECCode, @CoItemOriginCode, @CoItemCommodityCode, @ItemCustEndUser, @DelTermDescription
         FROM dbo.CoDConfig (
              @CoCoNum
            , @CoitemCoLine
            , @CoitemCoRelease
            , @CoitemItem
            , @CoitemShipSite
            , @CoOrderDate
            , @CoitemFeatStr ) as dconfig

         INSERT INTO @reportset (
            co_num,co_line,co_release,cast_co_release,item,site,salesman,
            FeatureDisplayStr,co_note_flag,billto_cust_note_flag,
            shipto_cust_note_flag,co_rowpointer,cust_rowpointer,
            billto_cust_rowpointer,shipto_cust_rowpointer,PrintKitonCustPaper,PromotionCode,item_content,
            drawing_nbr,delterm,ec_code,origin,comm_code,end_user,del_term_desc
            )
         SELECT TOP 1
            co_num,co_line,co_release,cast_co_release,item,site,salesman,
            FeatureDisplayStr,@CoNoteExistsFlag,@BillToCustNoteExistsFlag,
            @ShipToCustNoteExistsFlag,@CoRowPointer,@CustomerRowPointer,
            @BillToCustomerRowPointer,@ShipToCustomerRowPointer,@CoitemPrintKitComps,@PromotionCode,@ItemItemContent,
            @ItemDrawingNumber, @CoItemDeliveryIncoTerm, @CoItemECCode, @CoItemOriginCode, @CoItemCommodityCode, @ItemCustEndUser, @DelTermDescription
         FROM @reportset
         WHERE co_num = @CoCoNum
         AND co_line = @CoitemCoLine
         AND (@CastCoitemCoRelease IS NULL OR cast_co_release = @CastCoitemCoRelease)

         UPDATE @reportset
         SET FeatureDisplayStr = NULL
         FROM @reportset
         WHERE co_num = @CoCoNum
         AND co_line = @CoitemCoLine
         AND (@CastCoitemCoRelease IS NULL OR cast_co_release = @CastCoitemCoRelease)
         AND FeatureDisplayQty IS NOT NULL
      END

      set @TcAmtSalesTax = 0
      set @TcAmtSalesTax2 = 0
      
      IF @CoitemCursorCount = @CoitemCurrentCount
      BEGIN
  -- COMPUTE TAX FOR FREIGHT AND MISC AMOUNT, for the orig-site only.
         EXEC @Severity =  dbo.TaxCalcSp
            'R',  -- p-inv-type = Regular
            @CoTaxCode1,        -- p-tax-code1
            @CoTaxCode2,        -- p-tax-code2
            @TcAmtFreight2,      -- p-freight
            @CoFrtTaxCode1,     -- p-frt-tax-code1
            @CoFrtTaxCode2,     -- p-frt-tax-code2
            @TcAmtMisc,         -- p-misc
            @CoMscTaxCode1,     -- p-frt-tax-code1
            @CoMscTaxCode2,     -- p-frt-tax-code2
            @TodayDate,         -- p-inv-date, ? = use today
            @CoTermsCode,     -- p-terms-code
            @CoUseExchRate,
            @CustaddrCurrCode,
            @CurrencyPlaces, -- p-places-cp
            @CoExchRate,        -- p-exch-rate
            @TcAmtSalesTax  OUTPUT,
            @TcAmtSalesTax2 OUTPUT,
            @Infobar        OUTPUT,
            @pRefType       = 'O',
           @pHdrPtr        = @CoRowPointer
           , @LocalInit = 1
         , @Site = @CoitemShipSite

         delete tmp_tax_basis where ProcessId = @SessionId
         delete tmp_tax_calc where ProcessId = @SessionId
      END

      IF @Severity <> 0
      BEGIN
         INSERT INTO @ErrorLog
          (InfobarText, severity)
         VALUES
          (@Infobar,@Severity  )
         SET @Severity = 0
      END

      SET @TcAmtPrepaid = @CoPrepaidAmt + @CoPrepaidT

      SET @TcAmtDiscount = round(@TcAmtSales * @CoDisc / 100, @CurrencyPlaces)

      IF @TEuroExists = 1
      BEGIN
         EXEC @Severity = dbo.EuroPartSp
               @CustaddrCurrCode,
               @PPartOfEuro OUTPUT

         IF @PPartOfEuro = 1
         BEGIN
-- Check For Discount
            SET @TEuroTotal = @TEuroTotal - round ((@TEuroTotal *
                                        @CoDisc / 100), @ECurrencyPlaces)

-- Misc Charges
            SET @EuroConvAmount  = dbo.EuroCnvt (@TcAmtMisc,@CustaddrCurrCode,0,1)
            SET @TEuroTotal = round(@TEuroTotal + @EuroConvAmount, @ECurrencyPlaces)

-- Freight Charges
            SET @EuroConvAmount  = dbo.EuroCnvt (@TcAmtFreight,@CustaddrCurrCode,0,1)
            SET @TEuroTotal = round (@TEuroTotal + @EuroConvAmount, @ECurrencyPlaces)

-- Sales Tax
            SET @EuroConvAmount  = dbo.EuroCnvt (@TcAmtSalesTax,@CustaddrCurrCode,0,1)
            SET @TEuroTotal = round (@TEuroTotal + @EuroConvAmount, @ECurrencyPlaces)

--  Sales Tax 2
            SET @EuroConvAmount  = dbo.EuroCnvt (@TcAmtSalesTax2,@CustaddrCurrCode,0,1)
            SET @TEuroTotal = round (@TEuroTotal + @EuroConvAmount, @ECurrencyPlaces)

-- Prepaid Amount
            SET @EuroConvAmount  = dbo.EuroCnvt (@TcAmtPrepaid ,@CustaddrCurrCode,0,1)
            SET @TEuroTotal = round (@TEuroTotal + @EuroConvAmount, @ECurrencyPlaces)

         END
      END

      IF @CoQtyPackages = 0
         SET @CoQtyPackages = NULL

      SELECT @CoPortalOrder = co.portal_order
      from dbo.co
      WHERE co.co_num = @CoCoNum

      IF @CoPortalOrder = 1
         SET @CoitemDueDate = NULL

      IF @DisplayDate = 'P'
         SET @DisplayDateRep = @CoitemPromiseDate
      ELSE
         SET @DisplayDateRep = @CoitemDueDate

      IF @PrintPrice = 0
      BEGIN
         SET @TcCprPrice     = 0
         SET @TcAmtLineNet   = 0
         SET @TcAmtDiscount  = 0
         SET @TcAmtSalesTax  = 0
         SET @TcAmtSalesTax2 = 0
         SET @TcAmtFreight   = 0
         SET @TcAmtMisc      = 0
         SET @TcAmtFreight2  = 0
         SET @TcAmtMisc2     = 0
         SET @TcAmtPrepaid   = 0
         SET @TEuroTotal     = 0
         SET @TcAmtSales     = 0
      END
      else
      begin
         if @CoitemCursorCount = @CoitemCurrentCount
         begin
            set @TcAmtSalesTax = @TcAmtSalesTax + @AccumTax1Rounding
            set @TcAmtSalesTax2 = @TcAmtSalesTax2 + @AccumTax2Rounding
         end
         else
         begin
            set @AccumTax1Rounding = @AccumTax1Rounding + @TcAmtSalesTax - round(@TcAmtSalesTax, @CurrencyPlaces)
            set @AccumTax2Rounding = @AccumTax2Rounding + @TcAmtSalesTax2 - round(@TcAmtSalesTax2, @CurrencyPlaces)
         end
         set @TcAmtSalesTax  = round(@TcAmtSalesTax, @CurrencyPlaces)
         set @TcAmtSalesTax2 = round(@TcAmtSalesTax2, @CurrencyPlaces)
      end

      SET @OfficeAddr  = ISNULL(@OfficeAddr,'')
      SET @OfficePhone = ISNULL(@OfficePhone,'')
      SET @OfficeAddrFooter  = ISNULL(@OfficeAddrFooter,'')
      SET @OfficePhoneFooter = ISNULL(@OfficePhoneFooter,'')

-- Get Tax Code Descriptions
      SET @CoitemTaxCode1Desc = NULL
      IF @CoitemTaxCode1 IS NOT NULL
         SELECT @CoitemTaxCode1Desc = tc.description
         FROM taxcode_all as tc
         WHERE tc.tax_system    = 1
           AND tc.tax_code_type = CASE
                                          WHEN @TaxSystemTaxMode1 = 'A' THEN 'E'
                                          ELSE 'R'
                                       END
           AND tc.tax_code      = @CoitemTaxCode1
           and tc.site_ref = @CoitemShipSite

      SET @CoitemTaxCode2Desc = NULL
      IF @CoitemTaxCode2 IS NOT NULL
         SELECT @CoitemTaxCode2Desc = tc.description
         FROM taxcode_all as tc
         WHERE tc.tax_system    = 2
           AND tc.tax_code_type = CASE
                                          WHEN @TaxSystemTaxMode2 = 'A' THEN 'E'
                                          ELSE 'R'
                                       END
           AND tc.tax_code      = @CoitemTaxCode2
           and tc.site_ref = @CoitemShipSite

-- Get Configuration Details
      SET @CoitemConfigId = NULL
      IF @ConfigDetails <> 'N'
         SELECT
            @CoitemConfigId = cfg_main_all.config_id
         FROM cfg_main_all
         WHERE cfg_main_all.site_ref = @UserParmSite
           AND cfg_main_all.co_num   = @CoCoNum
           AND cfg_main_all.co_line  = @CoitemCoLine
      IF @CoitemConfigId IS NOT NULL
      BEGIN
         SET @CoitemHasCfg = 1
         INSERT INTO @ConfigSet (
            CompOperNum
          , CompSequence
          , CompCompName
          , CompQty
          , CompPrice
          , AttrName
          , AttrValue )
         SELECT
            CompOperNum
          , CompSequence
          , CompCompName
          , CompQty
          , CompPrice
          , AttrName
          , AttrValue
         FROM dbo.CfgGetConfigValues(@CoitemConfigId, @ConfigDetails)

         IF 0 = (SELECT COUNT(*) FROM @ConfigSet)
         BEGIN
            SET @CoitemHasCfg = 0
            INSERT INTO @ConfigSet (
               CompOperNum
             , CompSequence
             , CompCompName
             , CompQty
             , CompPrice
             , AttrName
             , AttrValue )
            VALUES (
               NULL
             , NULL
             , NULL
             , NULL
             , NULL
             , NULL
             , NULL )
         END

      END
      ELSE
      BEGIN
         SET @CoitemHasCfg = 0
         INSERT INTO @ConfigSet (
            CompOperNum
          , CompSequence
          , CompCompName
          , CompQty
          , CompPrice
          , AttrName
          , AttrValue )
         VALUES (
            NULL
          , NULL
          , NULL
          , NULL
          , NULL
          , NULL
          , NULL )
      END

-- Get DropShip Address
      SET @DropShipAddr = NULL
      SET @DropShipContact = NULL
      IF @CoitemCustNum IS NOT NULL
      BEGIN
         IF @CoDemandingSitePoNum IS NULL
         BEGIN
            SELECT @DropShipContact = customer.contact##2
            FROM customer
            WHERE customer.cust_num = @CoitemCustNum
              AND customer.cust_seq = @CoitemCustSeq
         END
         ELSE
         BEGIN
            SELECT @DropShipContact = customer.contact##2
            FROM customer_all AS customer
            WHERE customer.cust_num = @CoitemCustNum
              AND customer.cust_seq = @CoitemCustSeq
              AND customer.site_ref = @CoDemandingSite
         END
--         SET @DropShipAddr = dbo.FormatAddressWithContactSp ( @CoitemCustNum, @CoitemCustSeq, @DropShipContact)
           SET @DropShipAddr = dbo.FormatAddress ( @CoitemCustNum, @CoitemCustSeq)
      END

--Issue #76601
      DECLARE @SerialNumFound TinyInt
      SET @SerialNumFound = 0
      SET @SerialSerNum = NULL
--PRINT SERIAL NUMBERS
      IF  @IncludeSerialNumbers = 1
      BEGIN
         SET @SerialSetCount = 0

         SELECT @SerialSetCount = COUNT(serial.rowpointer) FROM rsvd_inv INNER JOIN serial
            ON rsvd_inv.rsvd_num = serial.rsvd_num
            WHERE rsvd_inv.ref_num = @CoCoNum
            AND rsvd_inv.ref_line = @CoitemCoLine
            AND rsvd_inv.ref_release = @CoitemCoRelease
            AND serial.stat = 'R'

         IF @SerialSetCount > 0
         BEGIN

            SET @SerialNumFound = 1
            SET @SerialSerNum = NULL

            -- Get @SerialSerNum for second WHERE clause
            SELECT TOP 1 @SerialSerNum = serial.ser_num FROM rsvd_inv INNER JOIN serial
               ON rsvd_inv.rsvd_num = serial.rsvd_num
               WHERE rsvd_inv.ref_num = @CoCoNum
               AND rsvd_inv.ref_line = @CoitemCoLine
               AND rsvd_inv.ref_release = @CoitemCoRelease
               AND serial.stat = 'R'

            INSERT INTO @Reportset (
               office_addr,date_appear,office_phone,co_num,cust_po,cust_num,cust_seq,ship_addr,bill_addr,
               cust_fax,curr_code,curr_desc,contact#1,contact#2,
               TaxIDLabel1, TaxIDLabel2, taxreg#1, taxreg#2, CustBillToTaxRegNum1,  CustBillToTaxRegNum2, CustShipToTaxRegNum1, CustShipToTaxRegNum2,
               shipdesc,termsdesc,qty_packs,pp_flag,order_date,item,
               cust_item,price,net_amount,co_line,co_release,cast_co_release,disp_date,
               qty_conv,um,item_desc,serial_num,co_note_flag,
               billto_cust_note_flag,shipto_cust_note_flag,Co_bln_Note_Flag,order_disc,sales_tax1,
               sales_tax2,freight,misc,prepaid,euro_total,co_text1,co_text2,
               co_text3,salesman,sales,
               JobrouteJob,JobrouteSuffix,JobrouteOperNum,
               FeatureDisplayQty,FeatureDisplayUM,FeatureDisplayDesc,
               FeatureDisplayStr,co_disc,co_rowpointer,cust_rowpointer,billto_cust_rowpointer,
               shipto_cust_rowpointer,Co_bln_RowPointer,site,LCR,
               dropship_contact, dropship_addr
               -- Configuration Details
             , HasCfgDetail
             , CompOperNum
             , CompSequence
             , CompCompName
             , CompQty
             , CompPrice
             , AttrName
             , AttrValue
             , Co_bln_Des
             , Co_item_Des
             , Co_item_DesOverview
             , Co_item_note_Flag
             , Co_item_Rowpointer
             -- Tax
             , tax_item_label1
             , tax_item_label2
             , coitem_tax_code1
             , coitem_tax_code2
             , coitem_tax_code1_desc
             , coitem_tax_code2_desc
             , sales_tax_label1
             , sales_tax_label2
             , TaxparmsNmbrOfSystems
             , TaxSystemPromptOnLine1
             , TaxSystemPromptOnLine2
             , Price_before_tax
             , Include_Tax_in_price
             , PrintKitonCustPaper
             , places_qty
             , qty_format
             , external_confirmation_ref
             , PromotionCode
             , item_content
             , drawing_nbr
             , delterm
             , ec_code
             , origin
             , comm_code
             , end_user
             , office_addr_footer
             , office_phone_footer
             , del_term_desc
             , url
             , email_addr
             , bank_name         
             , bank_transit_num  
             , bank_acct_no      
            )
            SELECT TOP 1
               @OfficeAddr,@DateToAppear,@OfficePhone,@CoCoNum,@CoCustPo,@CoCustNum,@CoCustSeq,@ShipTo,@BillTo,
               @CustaddrFaxNum,@CustaddrCurrCode,@CurrencyDescription,@CustomerContact1,@CustomerContact2,
               @TTaxIDLabel1, @TTaxIDLabel2, @TTaxRegNum1, @TTaxRegNum2, @TCustBillToTaxRegNum1, @TCustBillToTaxRegNum2, @TCustShipToTaxRegNum1, @TCustShipToTaxRegNum2,
               @ShipcodeDescription,@TermsDescription,@CoQtyPackages,@PrepaidFlag,@CoOrderDate,@CoitemItem,
               @CoitemCustItem,@TcCprPrice,@TcAmtLineNet,@CoitemCoLine,@CoitemCoRelease,@CastCoitemCoRelease,@DisplayDateRep,
               @CoitemQtyOrderedConv,@CoitemUM,@ItemDescription,serial.ser_num,@CoNoteExistsFlag,
               @BillToCustNoteExistsFlag,@ShipToCustNoteExistsFlag,@Co_blnNoteExistsFlag,@TcAmtDiscount,@TcAmtSalesTax,
               @TcAmtSalesTax2,@TcAmtFreight2,@TcAmtMisc2,@TcAmtPrepaid,@TEuroTotal,@CoText1,@CoText2,
               @CoText3,@TSlsman,@TcAmtSales,
               @JobrouteJob,@JobrouteSuffix,@JobrouteOperNum,
               @FeatureDisplayQty,@FeatureDisplayUM,@FeatureDisplayDesc,
               @FeatureDisplayStr,@CoDisc,@CoRowPointer,@CustomerRowPointer,@BillToCustomerRowPointer,
               @ShipToCustomerRowPointer,@Co_blnRowPointer,@UserParmSite,@LcrNum
             , @DropShipContact, @DropShipAddr
             -- Configuration Details
             , 0 -- @CoitemHasCfg
             , NULL
             , NULL
             , NULL
             , NULL
             , NULL
             , NULL
             , NULL
             , @Co_bln_Des
             , @coitemDescription
             , @coitemDescriptionOverview
             , @Coitem_allNoteExistsFlag
             , @coitemRowPointer
             -- Tax
             , @TaxItemLabel1
             , @TaxItemLabel2
             , @CoitemTaxCode1
             , @CoitemTaxCode2
             , @CoitemTaxCode1Desc
             , @CoitemTaxCode2Desc
             , @TaxAmtLabel1
             , @TaxAmtLabel2
             , @TaxparmsNmbrOfSystems
             , @TaxSystemPromptOnLine1
             , @TaxSystemPromptOnLine2
             , @PriceBeforeTax
             , @IncludeTaxInPrice
             , @CoitemPrintKitComps
             , @PlacesQtyUnit
             , @QtyUnitFormat
             , @ExternalConfirmationRef
             , @PromotionCode
             , @ItemItemContent
             , @ItemDrawingNumber
             , @CoItemDeliveryIncoTerm
             , @CoItemECCode
             , @CoItemOriginCode
             , @CoItemCommodityCode
             , @ItemCustEndUser
             , @OfficeAddrFooter
             , @OfficePhoneFooter
             , @DelTermDescription
             , @URL
             , @EmailAddr
             , @BankName      
             , @BankTransitNum
             , @BankAccountNo 
            FROM rsvd_inv INNER JOIN serial
            ON rsvd_inv.rsvd_num = serial.rsvd_num
            WHERE rsvd_inv.ref_num = @CoCoNum
            AND rsvd_inv.ref_line = @CoitemCoLine
            AND rsvd_inv.ref_release = @CoitemCoRelease
            AND serial.stat = 'R'

            IF @SerialSetCount > 1
               INSERT INTO @Reportset (
                office_addr,date_appear,office_phone,co_num,cust_po,cust_num,cust_seq,ship_addr,bill_addr,
                cust_fax,curr_code,curr_desc,contact#1,contact#2,
                TaxIDLabel1, TaxIDLabel2, taxreg#1, taxreg#2, CustBillToTaxRegNum1,  CustBillToTaxRegNum2, CustShipToTaxRegNum1, CustShipToTaxRegNum2,
                shipdesc,termsdesc,qty_packs,pp_flag,order_date,item,
                cust_item,price,net_amount,co_line,co_release,cast_co_release,disp_date,
                qty_conv,um,item_desc,serial_num,co_note_flag,
                billto_cust_note_flag,shipto_cust_note_flag,Co_bln_Note_Flag,order_disc,sales_tax1,
                sales_tax2,freight,misc,prepaid,euro_total,co_text1,co_text2,
                co_text3,salesman,sales,
                JobrouteJob,JobrouteSuffix,JobrouteOperNum,
                FeatureDisplayQty,FeatureDisplayUM,FeatureDisplayDesc,
                FeatureDisplayStr,co_disc,co_rowpointer,cust_rowpointer,billto_cust_rowpointer,
                shipto_cust_rowpointer,Co_bln_RowPointer,site,LCR,
                dropship_contact, dropship_addr
                -- Configuration Details
              , HasCfgDetail
              , CompOperNum
              , CompSequence
              , CompCompName
              , CompQty
              , CompPrice
              , AttrName
              , AttrValue
              , Co_bln_Des
              , Co_item_Des
              , Co_item_DesOverview
              , Co_item_note_Flag
              , Co_item_Rowpointer
              -- Tax
              , tax_item_label1
              , tax_item_label2
              , coitem_tax_code1
              , coitem_tax_code2
              , coitem_tax_code1_desc
              , coitem_tax_code2_desc
              , sales_tax_label1
              , sales_tax_label2
              , TaxparmsNmbrOfSystems
              , TaxSystemPromptOnLine1
              , TaxSystemPromptOnLine2
              , Price_before_tax
              , Include_Tax_in_price
              , PrintKitonCustPaper
              , places_qty
              , qty_format
              , external_confirmation_ref
              , PromotionCode
              , item_content
              , drawing_nbr
              , delterm
              , ec_code
              , origin
              , comm_code
              , end_user
              , office_addr_footer
              , office_phone_footer
              , del_term_desc
              , url
              , email_addr
              , bank_name        
              , bank_transit_num 
              , bank_acct_no     
             )
             SELECT
                @OfficeAddr,@DateToAppear,@OfficePhone,@CoCoNum,@CoCustPo,@CoCustNum,@CoCustSeq,@ShipTo,@BillTo,
                @CustaddrFaxNum,@CustaddrCurrCode,@CurrencyDescription,@CustomerContact1,@CustomerContact2,
                @TTaxIDLabel1, @TTaxIDLabel2, @TTaxRegNum1, @TTaxRegNum2, @TCustBillToTaxRegNum1, @TCustBillToTaxRegNum2, @TCustShipToTaxRegNum1, @TCustShipToTaxRegNum2,
                @ShipcodeDescription,@TermsDescription,@CoQtyPackages,@PrepaidFlag,@CoOrderDate,@CoitemItem,
                @CoitemCustItem,@TcCprPrice,  0          ,@CoitemCoLine,@CoitemCoRelease,@CastCoitemCoRelease,@DisplayDateRep,
                @CoitemQtyOrderedConv,@CoitemUM,@ItemDescription,serial.ser_num,@CoNoteExistsFlag,
                @BillToCustNoteExistsFlag,@ShipToCustNoteExistsFlag,@Co_blnNoteExistsFlag,@TcAmtDiscount,   0          ,
                  0            ,@TcAmtFreight2,@TcAmtMisc2,@TcAmtPrepaid,@TEuroTotal,@CoText1,@CoText2,
                @CoText3,@TSlsman,@TcAmtSales,
                @JobrouteJob,@JobrouteSuffix,@JobrouteOperNum,
                @FeatureDisplayQty,@FeatureDisplayUM,@FeatureDisplayDesc,
                @FeatureDisplayStr,  0  ,@CoRowPointer,@CustomerRowPointer,@BillToCustomerRowPointer,
                @ShipToCustomerRowPointer,@Co_blnRowPointer,@UserParmSite,@LcrNum
              , @DropShipContact, @DropShipAddr
              -- Configuration Details
              , 0
              , NULL
              , NULL
              , NULL
              , NULL
              , NULL
              , NULL
              , NULL
              , @Co_bln_Des
              , @coitemDescription
              , @coitemDescriptionOverview
              , @Coitem_allNoteExistsFlag
              , @coitemRowPointer       -- Tax
              , @TaxItemLabel1
              , @TaxItemLabel2
              , @CoitemTaxCode1
              , @CoitemTaxCode2
              , @CoitemTaxCode1Desc
              , @CoitemTaxCode2Desc
              , @TaxAmtLabel1
              , @TaxAmtLabel2
              , @TaxparmsNmbrOfSystems
              , @TaxSystemPromptOnLine1
              , @TaxSystemPromptOnLine2
              , 0
              , @IncludeTaxInPrice
              , @CoitemPrintKitComps
              , @PlacesQtyUnit
              , @QtyUnitFormat
              , @ExternalConfirmationRef
              , @PromotionCode
              , @ItemItemContent
              , @ItemDrawingNumber
              , @CoItemDeliveryIncoTerm
              , @CoItemECCode   
              , @CoItemOriginCode
              , @CoItemCommodityCode
              , @ItemCustEndUser
              , @OfficeAddrFooter
              , @OfficePhoneFooter
              , @DelTermDescription
              , @URL
              , @EmailAddr
              , @BankName      
              , @BankTransitNum
              , @BankAccountNo 
             -- FROM @ConfigSet , rsvd_inv INNER JOIN serial
             FROM rsvd_inv INNER JOIN serial
             ON rsvd_inv.rsvd_num = serial.rsvd_num
             WHERE rsvd_inv.ref_num = @CoCoNum
             AND rsvd_inv.ref_line = @CoitemCoLine
             AND rsvd_inv.ref_release = @CoitemCoRelease
             AND serial.stat = 'R'
             AND @SerialSerNum <> serial.ser_num

         END
      END

      SET @SerialSerNum = NULL

      IF @SerialNumFound = 0
      BEGIN
         INSERT INTO @reportset (
            office_addr,date_appear,office_phone,co_num,cust_po,cust_num,cust_seq,ship_addr,bill_addr,
            cust_fax,curr_code,curr_desc,contact#1,contact#2,
            TaxIDLabel1, TaxIDLabel2, taxreg#1, taxreg#2, CustBillToTaxRegNum1,  CustBillToTaxRegNum2, CustShipToTaxRegNum1, CustShipToTaxRegNum2,
            shipdesc,termsdesc,qty_packs,pp_flag,order_date,item,
            cust_item,price,net_amount,co_line,co_release,cast_co_release,disp_date,
            qty_conv,um,item_desc,serial_num,co_note_flag,
            billto_cust_note_flag,shipto_cust_note_flag,Co_bln_Note_Flag,order_disc,sales_tax1,
            sales_tax2,freight,misc,prepaid,euro_total,co_text1,co_text2,
            co_text3,salesman,sales,
            JobrouteJob,JobrouteSuffix,JobrouteOperNum,
            FeatureDisplayQty,FeatureDisplayUM,FeatureDisplayDesc,
            FeatureDisplayStr,co_disc,co_rowpointer,cust_rowpointer,billto_cust_rowpointer,
            shipto_cust_rowpointer,Co_bln_RowPointer,site,LCR
          , dropship_contact, dropship_addr
          -- Configuration Details
          , HasCfgDetail
          , CompOperNum
          , CompSequence
          , CompCompName
          , CompQty
          , CompPrice
          , AttrName
          , AttrValue
          , Co_bln_Des
          , Co_item_Des
          , Co_item_DesOverview
          , Co_item_note_Flag
          , Co_item_Rowpointer
          -- Tax
          , tax_item_label1
          , tax_item_label2
          , coitem_tax_code1
          , coitem_tax_code2
          , coitem_tax_code1_desc
          , coitem_tax_code2_desc
          , sales_tax_label1
          , sales_tax_label2
          , TaxparmsNmbrOfSystems
          , TaxSystemPromptOnLine1
          , TaxSystemPromptOnLine2
          , Price_before_tax
          , Include_Tax_in_price
          , PrintKitonCustPaper
          , places_qty
          , qty_format
          , external_confirmation_ref
          , PromotionCode
          , item_content
          , drawing_nbr
          , delterm
          , ec_code
          , origin
          , comm_code
          , end_user
          , office_addr_footer
          , office_phone_footer
          , del_term_desc
          , url
          , email_addr
          , bank_name        
          , bank_transit_num 
          , bank_acct_no     
         )
         SELECT TOP 1
            @OfficeAddr,@DateToAppear,@OfficePhone,@CoCoNum,@CoCustPo,@CoCustNum,@CoCustSeq,@ShipTo,@BillTo,
            @CustaddrFaxNum,@CustaddrCurrCode,@CurrencyDescription,@CustomerContact1,@CustomerContact2,
            @TTaxIDLabel1, @TTaxIDLabel2, @TTaxRegNum1, @TTaxRegNum2, @TCustBillToTaxRegNum1, @TCustBillToTaxRegNum2, @TCustShipToTaxRegNum1, @TCustShipToTaxRegNum2,
            @ShipcodeDescription,@TermsDescription,@CoQtyPackages,@PrepaidFlag,@CoOrderDate,@CoitemItem,
            @CoitemCustItem,@TcCprPrice,@TcAmtLineNet,@CoitemCoLine,@CoitemCoRelease,@CastCoitemCoRelease,@DisplayDateRep,
            @CoitemQtyOrderedConv,@CoitemUM,@ItemDescription,@SerialSerNum,@CoNoteExistsFlag,
            @BillToCustNoteExistsFlag,@ShipToCustNoteExistsFlag,@Co_blnNoteExistsFlag,@TcAmtDiscount,@TcAmtSalesTax,
            @TcAmtSalesTax2,@TcAmtFreight2,@TcAmtMisc2,@TcAmtPrepaid,@TEuroTotal,@CoText1,@CoText2,
            @CoText3,@TSlsman,@TcAmtSales,
            @JobrouteJob,@JobrouteSuffix,@JobrouteOperNum,
            @FeatureDisplayQty,@FeatureDisplayUM,@FeatureDisplayDesc,
            @FeatureDisplayStr,@CoDisc,@CoRowPointer,@CustomerRowPointer,@BillToCustomerRowPointer,
            @ShipToCustomerRowPointer,@Co_blnRowPointer,@UserParmSite,@LcrNum
          , @DropShipContact, @DropShipAddr
          -- Configuration Details
          , @CoitemHasCfg
          , CompOperNum
          , CompSequence
          , CompCompName
          , CompQty
          , CompPrice
          , AttrName
          , AttrValue
          , @Co_bln_Des
          , @coitemDescription
          , @coitemDescriptionOverview
          , @Coitem_allNoteExistsFlag
          , @coitemRowPointer
          -- Tax
          , @TaxItemLabel1
          , @TaxItemLabel2
          , @CoitemTaxCode1
          , @CoitemTaxCode2
          , @CoitemTaxCode1Desc
          , @CoitemTaxCode2Desc
          , @TaxAmtLabel1
          , @TaxAmtLabel2
          , @TaxparmsNmbrOfSystems
          , @TaxSystemPromptOnLine1
          , @TaxSystemPromptOnLine2
          , @PriceBeforeTax
          , @IncludeTaxInPrice
          , @CoitemPrintKitComps
          , @PlacesQtyUnit
          , @QtyUnitFormat
          , @ExternalConfirmationRef
          , @PromotionCode
          , @ItemItemContent
          , @ItemDrawingNumber
          , @CoItemDeliveryIncoTerm
          , @CoItemECCode   
          , @CoItemOriginCode
          , @CoItemCommodityCode
          , @ItemCustEndUser
          , @OfficeAddrFooter
          , @OfficePhoneFooter
          , @DelTermDescription
          , @URL
          , @EmailAddr
          , @BankName      
          , @BankTransitNum
          , @BankAccountNo 
         FROM @ConfigSet
      END

      SET @ConfigSetCount = NULL
      SELECT @ConfigSetCount = COUNT(*) FROM @ConfigSet

      IF @ConfigSetCount > 1 OR (@SerialNumFound = 1 AND @ConfigSetCount = 1)
      BEGIN
         IF @SerialNumFound = 0
         BEGIN
            SELECT TOP 1 @CompOperNum = CompOperNum, @AttrName = AttrName FROM @ConfigSet
            DELETE @ConfigSet WHERE @CompOperNum = CompOperNum AND @AttrName  = AttrName
         END

        INSERT INTO @reportset (
         office_addr,date_appear,office_phone,co_num,cust_po,cust_num,cust_seq,ship_addr,bill_addr,
         cust_fax,curr_code,curr_desc,contact#1,contact#2,
         TaxIDLabel1, TaxIDLabel2, taxreg#1, taxreg#2, CustBillToTaxRegNum1,  CustBillToTaxRegNum2, CustShipToTaxRegNum1, CustShipToTaxRegNum2,
         shipdesc,termsdesc,qty_packs,pp_flag,order_date,item,
         cust_item,price,net_amount,co_line,co_release,cast_co_release,disp_date,
         qty_conv,um,item_desc,serial_num,co_note_flag,
         billto_cust_note_flag,shipto_cust_note_flag,Co_bln_Note_Flag,order_disc,sales_tax1,
         sales_tax2,freight,misc,prepaid,euro_total,co_text1,co_text2,
         co_text3,salesman,sales,
         JobrouteJob,JobrouteSuffix,JobrouteOperNum,
         FeatureDisplayQty,FeatureDisplayUM,FeatureDisplayDesc,
         FeatureDisplayStr,co_disc,co_rowpointer,cust_rowpointer,billto_cust_rowpointer,
         shipto_cust_rowpointer,Co_bln_RowPointer,site,LCR
          , dropship_contact, dropship_addr
          -- Configuration Details
          , HasCfgDetail
          , CompOperNum
          , CompSequence
          , CompCompName
          , CompQty
          , CompPrice
          , AttrName
          , AttrValue
          , Co_bln_Des
          , Co_item_Des
          , Co_item_DesOverview
          , Co_item_note_Flag
          , Co_item_Rowpointer
          -- Tax
          , tax_item_label1
          , tax_item_label2
          , coitem_tax_code1
          , coitem_tax_code2
          , coitem_tax_code1_desc
          , coitem_tax_code2_desc
          , sales_tax_label1
          , sales_tax_label2
          , TaxparmsNmbrOfSystems
          , TaxSystemPromptOnLine1
          , TaxSystemPromptOnLine2
          , Price_before_tax
          , Include_Tax_in_price
          , PrintKitonCustPaper
          , places_qty
          , qty_format
          , external_confirmation_ref
          , PromotionCode
          , item_content
          , drawing_nbr
          , delterm
          , ec_code
          , origin
          , comm_code
          , end_user 
          , office_addr_footer
          , office_phone_footer
          , del_term_desc
          , url
          , email_addr
          , bank_name       
          , bank_transit_num
          , bank_acct_no    
         )
         SELECT
         @OfficeAddr,@DateToAppear,@OfficePhone,@CoCoNum,@CoCustPo,@CoCustNum,@CoCustSeq,@ShipTo,@BillTo,
         @CustaddrFaxNum,@CustaddrCurrCode,@CurrencyDescription,@CustomerContact1,@CustomerContact2,
         @TTaxIDLabel1, @TTaxIDLabel2, @TTaxRegNum1, @TTaxRegNum2, @TCustBillToTaxRegNum1, @TCustBillToTaxRegNum2, @TCustShipToTaxRegNum1, @TCustShipToTaxRegNum2,
         @ShipcodeDescription,@TermsDescription,@CoQtyPackages,@PrepaidFlag,@CoOrderDate,@CoitemItem,
         @CoitemCustItem,@TcCprPrice, 0           ,@CoitemCoLine,@CoitemCoRelease,@CastCoitemCoRelease,@DisplayDateRep,
         @CoitemQtyOrderedConv,@CoitemUM,@ItemDescription,@SerialSerNum,@CoNoteExistsFlag,
         @BillToCustNoteExistsFlag,@ShipToCustNoteExistsFlag,@Co_blnNoteExistsFlag,@TcAmtDiscount, 0            ,
         0              ,@TcAmtFreight2,@TcAmtMisc2,@TcAmtPrepaid,@TEuroTotal,@CoText1,@CoText2,
         @CoText3,@TSlsman,@TcAmtSales,
         @JobrouteJob,@JobrouteSuffix,@JobrouteOperNum,
         @FeatureDisplayQty,@FeatureDisplayUM,@FeatureDisplayDesc,
         @FeatureDisplayStr, 0     ,@CoRowPointer,@CustomerRowPointer,@BillToCustomerRowPointer,
         @ShipToCustomerRowPointer,@Co_blnRowPointer,@UserParmSite,@LcrNum
          , @DropShipContact, @DropShipAddr
          -- Configuration Details
          , @CoitemHasCfg
          , CompOperNum
          , CompSequence
          , CompCompName
          , CompQty
          , CompPrice
          , AttrName
          , AttrValue
          , @Co_bln_Des
          , @coitemDescription
          , @coitemDescriptionOverview
          , @Coitem_allNoteExistsFlag
          , @coitemRowPointer
          -- Tax
          , @TaxItemLabel1
          , @TaxItemLabel2
          , @CoitemTaxCode1
          , @CoitemTaxCode2
          , @CoitemTaxCode1Desc
          , @CoitemTaxCode2Desc
          , @TaxAmtLabel1
          , @TaxAmtLabel2
          , @TaxparmsNmbrOfSystems
          , @TaxSystemPromptOnLine1
          , @TaxSystemPromptOnLine2
          , 0
          , @IncludeTaxInPrice
          , @CoitemPrintKitComps
          , @PlacesQtyUnit
          , @QtyUnitFormat
          , @ExternalConfirmationRef
          , @PromotionCode
          , @ItemItemContent
          , @ItemDrawingNumber
          , @CoItemDeliveryIncoTerm
          , @CoItemECCode   
          , @CoItemOriginCode
          , @CoItemCommodityCode
          , @ItemCustEndUser
          , @OfficeAddrFooter
          , @OfficePhoneFooter
          , @DelTermDescription
          , @URL
          , @EmailAddr
          , @BankName      
          , @BankTransitNum
          , @BankAccountNo 
         FROM @ConfigSet
      END

      SET @TcAmtMisc = 0
      SET @TcAmtFreight = 0
-- Clear Configuration Values
      DELETE FROM @ConfigSet
   END
   CLOSE       CoItemAllCrs
   DEALLOCATE  CoItemAllCrs  --END COITEM

   exec dbo.ReleaseTmpTaxTablesSp
     @PSessionId = @SessionId
   , @LocalInit  = 1

   if @AtLeastOneLine = 0
      INSERT INTO @reportset (
         office_addr,date_appear,office_phone,co_num,cust_po,cust_num,cust_seq,ship_addr,bill_addr,
         cust_fax,curr_code,curr_desc,contact#1,contact#2,
         TaxIDLabel1, TaxIDLabel2, taxreg#1, taxreg#2, CustBillToTaxRegNum1,  CustBillToTaxRegNum2, CustShipToTaxRegNum1, CustShipToTaxRegNum2,
         shipdesc,termsdesc,qty_packs,pp_flag,order_date,
         co_note_flag,
         billto_cust_note_flag,shipto_cust_note_flag,Co_bln_Note_Flag,order_disc,sales_tax1,
         sales_tax2,freight,misc,prepaid,euro_total,co_text1,co_text2,
         co_text3,salesman,sales,net_amount,
         co_disc,co_rowpointer,cust_rowpointer,billto_cust_rowpointer,
         shipto_cust_rowpointer,site,LCR
       , sales_tax_label1
       , sales_tax_label2
       , TaxparmsNmbrOfSystems
       , TaxSystemPromptOnLine1
       , TaxSystemPromptOnLine2
       , Price_before_tax
       , Include_Tax_in_price
       , places_qty
       , qty_format
       , external_confirmation_ref
       , PromotionCode
       , item_content
       , drawing_nbr
       , delterm
       , ec_code
       , origin
       , comm_code
       , end_user
       , office_addr_footer
       , office_phone_footer
       , del_term_desc
       , url
       , email_addr
       , bank_name       
       , bank_transit_num
       , bank_acct_no    
      )
      SELECT
         @OfficeAddr,@DateToAppear,@OfficePhone,@CoCoNum,@CoCustPo,@CoCustNum,@CoCustSeq,@ShipTo,@BillTo,
         @CustaddrFaxNum,@CustaddrCurrCode,@CurrencyDescription,@CustomerContact1,@CustomerContact2,
         @TTaxIDLabel1, @TTaxIDLabel2, @TTaxRegNum1, @TTaxRegNum2, @TCustBillToTaxRegNum1, @TCustBillToTaxRegNum2, @TCustShipToTaxRegNum1, @TCustShipToTaxRegNum2,
         @ShipcodeDescription,@TermsDescription,@CoQtyPackages,@PrepaidFlag,@CoOrderDate,
         @CoNoteExistsFlag,
         @BillToCustNoteExistsFlag,@ShipToCustNoteExistsFlag,@Co_blnNoteExistsFlag,0,@TcAmtSalesTax,
         @TcAmtSalesTax2,@TcAmtFreight2,@TcAmtMisc2,@TcAmtPrepaid,@TEuroTotal,@CoText1,@CoText2,
         @CoText3,@TSlsman,@TcAmtSales,0,
         0,@CoRowPointer,@CustomerRowPointer,@BillToCustomerRowPointer,
         @ShipToCustomerRowPointer,@UserParmSite,@LcrNum
       , @TaxAmtLabel1
       , @TaxAmtLabel2
       , @TaxparmsNmbrOfSystems
       , @TaxSystemPromptOnLine1
       , @TaxSystemPromptOnLine2
       , @PriceBeforeTax
       , @IncludeTaxInPrice
       , @PlacesQtyUnit
       , @QtyUnitFormat
       , @ExternalConfirmationRef
       , @PromotionCode
       , @ItemItemContent
       , @ItemDrawingNumber
       , @CoItemDeliveryIncoTerm
       , @CoItemECCode   
       , @CoItemOriginCode
       , @CoItemCommodityCode
       , @ItemCustEndUser
       , @OfficeAddrFooter
       , @OfficePhoneFooter
       , @DelTermDescription
       , @URL
       , @EmailAddr
       , @BankName      
       , @BankTransitNum
       , @BankAccountNo 

   IF  @PrintPlanningItemMaterials = 1 AND @CoitemFeatStr IS NOT NULL
   BEGIN
      UPDATE @reportset
         SET freight = @TcAmtFreight2, misc = @TcAmtMisc2, prepaid = @TcAmtPrepaid,
         price_before_tax = @PriceBeforeTax, include_tax_in_price = @IncludeTaxInPrice,
         sales_tax_label1 = @TaxItemLabel1, sales_tax_label2 = @TaxItemLabel2,
         co_text1 = @CoText1, co_text2 = @CoText2, co_text3 = @CoText3,
         euro_total = @TEuroTotal
      WHERE
      unique_val = (SELECT top 1 (unique_val)
               FROM @reportset
               WHERE co_num = @CoCoNum
               AND FeatureDisplayStr IS NULL
               AND FeatureDisplayUM is NOT NULL
               Order by co_line desc -- Feature materials last (in order)
                       , isnull(co_release, 0) desc
               , unique_val desc
               )

      /* Add header info to the planning materials */
      UPDATE @reportset
         SET
            office_addr = @OfficeAddr, date_appear = @DateToAppear, office_phone = @OfficePhone,
            cust_po = @CoCustPo, cust_num = @CoCustNum, cust_seq = @CoCustSeq, ship_addr = @ShipTo, bill_addr = @BillTo,
            cust_fax = @CustaddrFaxNum, curr_code = @CustaddrCurrCode, curr_desc = @CurrencyDescription,
            contact#1 = @CustomerContact1, contact#2 = @CustomerContact2,
            TaxIDLabel1 = @TTaxIDLabel1, TaxIDLabel2 = @TTaxIDLabel2, taxreg#1 = @TTaxRegNum1, taxreg#2 = @TTaxRegNum2,
            CustBillToTaxRegNum1 = @TCustBillToTaxRegNum1, CustBillToTaxRegNum2 = @TCustBillToTaxRegNum2, CustShipToTaxRegNum1 = @TCustShipToTaxRegNum1, CustShipToTaxRegNum2 = @TCustShipToTaxRegNum2,
            shipdesc = @ShipcodeDescription, termsdesc = @TermsDescription, qty_packs = @CoQtyPackages,
            pp_flag = @PrepaidFlag, order_date = @CoOrderDate
      WHERE co_num = @CoCoNum
         AND ((FeatureDisplayStr IS NULL AND FeatureDisplayUM is NOT NULL) OR (FeatureDisplayStr IS NOT NULL AND FeatureDisplayUM is NULL))
   END
   
   SET @CurrencyPriceFormat = dbo.FixMaskForCrystal( @CurrencyPriceFormat, dbo.GetWinRegDecGroup() )
   SET @CurrencyFormat = dbo.FixMaskForCrystal( @CurrencyFormat, dbo.GetWinRegDecGroup() )
   SET @CurrencyTotFormat = dbo.FixMaskForCrystal( @CurrencyTotFormat, dbo.GetWinRegDecGroup() )

   SELECT @IntPosition = CHARINDEX( '.', @CurrencyTotFormat)
   IF @IntPosition > 0
      SET @CurrencyTotPlaces = LEN(SUBSTRING( @CurrencyTotFormat, @IntPosition+1, LEN(@CurrencyTotFormat)))
   Update @reportset 
      SET 
         CurrencyPriceFormat = @CurrencyPriceFormat,CurrencyPricePlaces = @CurrencyPricePlaces,
         CurrencyFormat = @CurrencyFormat, CurrencyPlaces = @CurrencyPlaces,
         CurrencyTotFormat = @CurrencyTotFormat, CurrencyTotPlaces = @CurrencyTotPlaces
   WHERE co_num = @CoCoNum
END
CLOSE      CoAllCrs
DEALLOCATE CoAllCrs --END CO-LOOP

END_OF_PROG:
IF @Severity <> 0
BEGIN
 --Delete from @reportset
   IF @TaskId is not null
      EXEC dbo.AddProcessErrorLogSp @ProcessId = @TaskId, @InfobarText = @Infobar, @MessageSeverity = @Severity
END

DECLARE SurchargeCursor CURSOR local STATIC FOR
SELECT
  item
, salesman
, co_num
, co_line
, co_release
, ISNULL(qty_conv,0)
, um
, item_content
, CurrencyPlaces
FROM @Reportset

OPEN SurchargeCursor
WHILE @@ERROR = 0
BEGIN
   FETCH SurchargeCursor INTO
         @CoitemItem
       , @TSlsman
       , @CoCoNum
       , @CoitemCoLine
       , @CoitemCoRelease
       , @CoitemQtyOrderedConv
       , @CoitemUM
       , @ItemItemContent
       , @CurrencyPlaces
   IF @@FETCH_STATUS = -1
      BREAK

   SET @SumSurcharge = 0

   IF @ItemItemContent = 1
   BEGIN
      EXEC @Severity = dbo.GetItemSurchargeSp
           @Item            = @CoitemItem
         , @RefType         = 'O'
         , @RefNum          = @CoCoNum
         , @RefLine         = @CoitemCoLine
         , @RefRelease      = @CoitemCoRelease
         , @InvNum          = NULL
         , @TransDate       = NULL
         , @RefItemContent  = NULL
         , @SumSurcharge    = @SumSurcharge OUTPUT

      IF @Severity <> 0
         BREAK

      SET @UomConvFactor = dbo.Getumcf(@CoitemUM,@CoitemItem,@CoCustNum,'C')
      SET @TQtyConv      = dbo.UomConvQty(@CoitemQtyOrderedConv,@UomConvFactor,'To Base')
      SET @TotalSurcharge = round(@SumSurcharge * @TQtyConv, @CurrencyPlaces)
   END

   INSERT INTO @SurchargeTable
    (
      item
    , salesman
    , co_num
    , co_line
    , co_release
    , TotalSurcharge
    )
    VALUES
    (
      @CoitemItem
    , @TSlsman
    , @CoCoNum
    , @CoitemCoLine
    , @CoitemCoRelease
    , @TotalSurcharge
    )

END
CLOSE      SurchargeCursor
DEALLOCATE SurchargeCursor



--order by slsman or co_num
IF @Sortby = 'S'
   SELECT   co.Uf_LineDisc, coi.disc as KPIDisc,Rep.*,sur.SumTotalSurcharge, 
   coi.whse,
   case
		when co.ssspj_override = 1  then    ', Account: ' + isnull(co.ssspj_carrier_account,'')
   else ', Account: ' + isnull(ca.carrier_account, '') 
   end
   as carrier_account,
   co.Taken_by
   FROM @Reportset Rep
   
   INNER JOIN (SELECT salesman, SUM(TotalSurcharge) AS SumTotalSurcharge FROM @SurchargeTable GROUP BY salesman) AS sur
   ON Rep.salesman = sur.salesman
   LEFT OUTER JOIN coitem coi on Rep.co_num = coi.co_num and Rep.co_line = coi.co_line and Rep.co_release = coi.co_release
   LEFT OUTER JOIN custaddr ca on Rep.cust_num = ca.cust_num and Rep.cust_seq = ca.cust_seq
   LEFT OUTER JOIN co co on Rep.co_num = co.co_num
   WHERE @Severity = 0
   ORDER BY
      salesman ASC
      , rep.co_num ASC, co_line ASC, isnull(Rep.co_release, 0) ASC, CompOperNum, CompSequence
      , isnull(UM, '') DESC  -- Non-feature record first
      , isnull(FeatureDisplayStr, '') DESC  -- Feature string second
      , JobrouteJob  -- Feature materials last (in order)
      , JobrouteSuffix
      , JobrouteOperNum
ELSE
BEGIN
   SELECT  co.Uf_LineDisc,coi.disc as KPIDisc, Rep.*,sur.SumTotalSurcharge,
    coi.whse,
     case
		when co.ssspj_override = 1  then ', Account: ' + isnull(co.ssspj_carrier_account,'')
		else   ', Account: ' + isnull(ca.carrier_account, '') 

		end
	
   as carrier_account, 
    co.taken_by
   FROM @Reportset Rep
  
   INNER JOIN (SELECT co_num, SUM(TotalSurcharge) AS SumTotalSurcharge FROM @SurchargeTable GROUP BY co_num) AS sur
   ON Rep.co_num = sur.co_num
   LEFT OUTER JOIN coitem coi on Rep.co_num = coi.co_num and Rep.co_line = coi.co_line and Rep.co_release = coi.co_release
   LEFT OUTER JOIN custaddr ca on Rep.cust_num = ca.cust_num and Rep.cust_seq = ca.cust_seq
   LEFT OUTER JOIN co co on Rep.co_num = co.co_num
   WHERE @Severity = 0
   ORDER BY
      rep.co_num ASC, co_line ASC, isnull(Rep.co_release, 0) ASC, CompOperNum, CompSequence
      , isnull(UM, '') DESC  -- Non-feature record first
      , isnull(FeatureDisplayStr, '') DESC  -- Feature string second
      , JobrouteJob  -- Feature materials last (in order)
      , JobrouteSuffix
      , JobrouteOperNum
END

-- Create OrderShip BOD
DECLARE @OrderShipNum CoNumType
, @ActionExpression NVARCHAR(60)

SET @ActionExpression = 'Replace' --Unable to deturmin if Add or Replace

DECLARE OrderShipCrs CURSOR LOCAL STATIC READ_ONLY
FOR
   SELECT DISTINCT Rep.co_num
   FROM @Reportset Rep
   WHERE @Severity = 0
OPEN OrderShipCrs

Set @Severity = 0

WHILE @Severity = 0
BEGIN
  FETCH OrderShipCrs INTO
    @OrderShipNum
  IF @@FETCH_STATUS = -1
    BREAK
  EXEC @Severity = dbo.RemoteMethodForReplicationTargetsSp
       'ESBSLCos'
       , 'TriggerSalesOrderSyncSp'
       , @Infobar OUTPUT
       , @OrderShipNum
       , NULL
       , @ActionExpression

  IF @Severity != 0
    EXEC dbo.RaiseErrorSP @Infobar, @Severity, 1

END

CLOSE OrderShipCrs
DEALLOCATE OrderShipCrs



EXIT_SP:
IF @ReleaseTmpTaxTables = 1
   EXEC @Severity =  dbo.ReleaseTmpTaxTablesSp @SessionId

IF @TaskId is not null
and EXISTS (SELECT TOP 1 * FROM @ErrorLog)
BEGIN
   DECLARE ErrorLogCrs CURSOR LOCAL STATIC FOR
   SELECT
      InfobarText,
      Severity
   FROM @ErrorLog
   OPEN ErrorLogCrs
   WHILE 1 = 1
   BEGIN
      FETCH ErrorLogCrs INTO
         @Infobar,
         @Severity

      IF @@FETCH_STATUS = -1
         BREAK

      EXEC dbo.AddProcessErrorLogSp @ProcessId = @TaskId, @InfobarText = @Infobar, @MessageSeverity = @Severity

   END
   CLOSE      ErrorLogCrs
   DEALLOCATE ErrorLogCrs
END

COMMIT TRANSACTION
EXEC dbo.CloseSessionContextSp @SessionID = @RptSessionID

IF OBJECT_ID('vrtx_parm') IS NOT NULL
BEGIN
   EXEC dbo.UndefineVariableSp
        'SSSVTXTaxCalcForceCalc'
  , @Infobar OUTPUT
END

RETURN @Severity

GO


