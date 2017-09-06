USE [KPI_App]
GO

/****** Object:  Table [dbo].[_KPI_ItemTravelerAndCreateDate]    Script Date: 08/30/2017 15:51:29 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[_KPI_ItemTravelerAndCreateDate](
	[Item #] [float] NULL,
	[CSIItem] [nvarchar](255) NULL,
	[Description] [nvarchar](255) NULL,
	[Date entered] [datetime] NULL,
	[Traveler code] [float] NULL
) ON [PRIMARY]

GO


