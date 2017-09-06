USE [KPI_App]
GO

/****** Object:  Table [dbo].[_KPI_ContractCustomers]    Script Date: 08/30/2017 15:51:21 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[_KPI_ContractCustomers](
	[ContractCustomerID] [numeric](18, 0) IDENTITY(1,1) NOT NULL,
	[ContractID] [nvarchar](10) NOT NULL,
	[CustomerID] [nvarchar](8) NOT NULL,
 CONSTRAINT [PK_CONTRACT_CUSTOMERS] PRIMARY KEY CLUSTERED 
(
	[ContractCustomerID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO


