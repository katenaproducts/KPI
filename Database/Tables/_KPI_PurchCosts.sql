USE [KPI_App]
GO

/****** Object:  Table [dbo].[_KPI_PurchCosts]    Script Date: 08/30/2017 15:51:31 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[_KPI_PurchCosts](
	[PurchItem] [nvarchar](255) NULL,
	[Description] [nvarchar](255) NULL,
	[Standard Cost] [float] NULL
) ON [PRIMARY]

GO


