USE [KPI_App]
GO

/****** Object:  Table [dbo].[_KPI_Serials]    Script Date: 08/30/2017 15:51:34 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[_KPI_Serials](
	[site_ref] [dbo].[SiteType] NOT NULL,
	[Item] [dbo].[ItemType] NOT NULL,
	[SerialNum] [dbo].[SerNumType] NOT NULL,
	[Stat] [nvarchar](1) NOT NULL,
	[Ref_type] [nvarchar](1) NULL,
	[RefNum] [dbo].[PoNumType] NULL,
	[RefLine] [int] NULL,
	[RefLineSuf] [int] NULL,
	[Pack_Num] [dbo].[PackNumType] NULL,
	[InvNum] [dbo].[InvNumType] NULL,
	[TransDate] [datetime] NULL,
	[CreatedBy] [dbo].[UsernameType] NOT NULL,
	[UpdatedBy] [dbo].[UsernameType] NOT NULL,
	[CreateDate] [dbo].[CurrentDateType] NOT NULL,
	[RecordDate] [dbo].[CurrentDateType] NOT NULL,
	[UserId] [tinyint] NOT NULL,
 CONSTRAINT [PI_KPI_Serials] UNIQUE NONCLUSTERED 
(
	[site_ref] ASC,
	[SerialNum] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO


