USE [KPI_App]
GO

/****** Object:  Table [dbo].[_KPI_BarCodes]    Script Date: 08/30/2017 15:51:07 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[_KPI_BarCodes](
	[LineNo] [int] IDENTITY(0,1) NOT NULL,
	[site_ref] [dbo].[SiteType] NOT NULL,
	[BarCode] [nvarchar](100) NOT NULL,
	[Item] [dbo].[ItemType] NOT NULL,
	[SerialNum] [dbo].[SerNumType] NOT NULL,
	[MatlTransNum] [int] NOT NULL,
	[Lot] [dbo].[LotType] NULL,
	[Qty] [decimal](18, 8) NULL,
	[GTIN] [nvarchar](50) NULL,
	[ExpiryDate] [nvarchar](50) NULL,
	[SessionID] [dbo].[RowPointerType] NULL,
	[Ref_type] [nvarchar](1) NULL,
	[RefNum] [dbo].[PoNumType] NULL,
	[RefLine] [int] NULL,
	[RefLineSuf] [int] NULL,
	[Pack_Num] [dbo].[PackNumType] NULL,
	[InvNum] [dbo].[InvNumType] NULL,
	[TransDate] [datetime] NULL,
	[NoteExistsFlag] [dbo].[FlagNyType] NOT NULL,
	[CreatedBy] [dbo].[UsernameType] NOT NULL,
	[UpdatedBy] [dbo].[UsernameType] NOT NULL,
	[CreateDate] [dbo].[CurrentDateType] NOT NULL,
	[RecordDate] [dbo].[CurrentDateType] NOT NULL,
	[RowPointer] [dbo].[RowPointerType] NOT NULL,
	[InWorkflow] [dbo].[FlagNyType] NOT NULL,
	[UserId] [tinyint] NOT NULL,
 CONSTRAINT [PI_Line_BarCodes] PRIMARY KEY CLUSTERED 
(
	[LineNo] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = ON, IGNORE_DUP_KEY = ON, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 80) ON [PRIMARY],
 CONSTRAINT [IX__KPI_BarCodes] UNIQUE NONCLUSTERED 
(
	[site_ref] ASC,
	[RowPointer] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = ON, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 80) ON [PRIMARY],
 CONSTRAINT [IX2_KPI_BarCodes] UNIQUE NONCLUSTERED 
(
	[site_ref] ASC,
	[UserId] ASC,
	[CreatedBy] ASC,
	[RowPointer] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = ON, IGNORE_DUP_KEY = ON, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 80) ON [PRIMARY],
 CONSTRAINT [PI_KPI_BarCodes] UNIQUE NONCLUSTERED 
(
	[site_ref] ASC,
	[BarCode] ASC,
	[Item] ASC,
	[SerialNum] ASC,
	[MatlTransNum] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = ON, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 80) ON [PRIMARY]
) ON [PRIMARY]

GO

ALTER TABLE [dbo].[_KPI_BarCodes] ADD  CONSTRAINT [DF__KPI_BarCodes_site_ref]  DEFAULT ((0)) FOR [site_ref]
GO

ALTER TABLE [dbo].[_KPI_BarCodes] ADD  CONSTRAINT [DF__KPI_BarCodes_MatlTransNum]  DEFAULT ((0)) FOR [MatlTransNum]
GO


