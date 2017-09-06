USE [KPI_App]
GO

/****** Object:  Table [dbo].[_KPI_Traveler]    Script Date: 08/30/2017 15:51:37 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[_KPI_Traveler](
	[Receipt_ID] [nvarchar](50) NOT NULL,
	[Trans_num] [dbo].[MatlTransNumType] NOT NULL,
	[Po_num] [dbo].[PoNumType] NOT NULL,
 CONSTRAINT [PI_KPI_Traveler] PRIMARY KEY CLUSTERED 
(
	[Po_num] ASC,
	[Trans_num] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO


