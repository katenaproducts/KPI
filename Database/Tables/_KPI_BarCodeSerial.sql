USE [KPI_App]
GO

/****** Object:  Table [dbo].[_KPI_BarCodeSerial]    Script Date: 08/30/2017 15:51:10 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[_KPI_BarCodeSerial](
	[site_ref] [dbo].[SiteType] NOT NULL,
	[Item] [dbo].[ItemType] NOT NULL,
	[SerialNum] [dbo].[SerNumType] NOT NULL,
	[Stat] [nvarchar](1) NULL,
	[SourceType] [nvarchar](1) NULL,
	[VendNum] [dbo].[VendNumType] NULL,
	[SourceRefNum] [nvarchar](10) NULL,
	[SourceRefLine] [int] NULL,
	[DestType] [nvarchar](1) NULL,
	[DestRefNum] [nvarchar](10) NULL,
	[DestRefLine] [int] NULL,
	[InvNum] [dbo].[InvNumType] NULL,
	[CustNum] [dbo].[CustNumType] NULL,
	[CustSeq] [dbo].[CustSeqType] NULL,
	[NoteExistsFlag] [dbo].[FlagNyType] NOT NULL,
	[CreatedBy] [dbo].[UsernameType] NOT NULL,
	[UpdatedBy] [dbo].[UsernameType] NOT NULL,
	[CreateDate] [dbo].[CurrentDateType] NOT NULL,
	[RecordDate] [dbo].[CurrentDateType] NOT NULL,
	[RowPointer] [dbo].[RowPointerType] NOT NULL,
	[InWorkflow] [dbo].[FlagNyType] NOT NULL,
	[UserId] [tinyint] NOT NULL,
 CONSTRAINT [PK_KPI_Serial] PRIMARY KEY CLUSTERED 
(
	[site_ref] ASC,
	[Item] ASC,
	[SerialNum] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO


