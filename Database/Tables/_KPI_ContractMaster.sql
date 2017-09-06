USE [KPI_App]
GO

/****** Object:  Table [dbo].[_KPI_ContractMaster]    Script Date: 08/30/2017 15:51:26 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[_KPI_ContractMaster](
	[ContractID] [nvarchar](10) NOT NULL,
	[ContractDescription] [nvarchar](200) NULL,
	[ContractBasis] [nvarchar](10) NULL,
 CONSTRAINT [PK_CONTRACT_MASTER] PRIMARY KEY CLUSTERED 
(
	[ContractID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO


