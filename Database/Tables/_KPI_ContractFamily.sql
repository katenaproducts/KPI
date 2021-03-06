USE [KPI_App]
GO

/****** Object:  Table [dbo].[_KPI_ContractFamily]    Script Date: 08/30/2017 15:51:23 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[_KPI_ContractFamily](
	[ContractFamilyID] [numeric](18, 0) IDENTITY(1,1) NOT NULL,
	[ContractID] [nvarchar](10) NOT NULL,
	[FamilyCode] [nvarchar](10) NOT NULL,
	[DiscountRule] [numeric](18, 0) NOT NULL,
 CONSTRAINT [PK_CONTRACT_PRODUCTS] PRIMARY KEY CLUSTERED 
(
	[ContractFamilyID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

ALTER TABLE [dbo].[_KPI_ContractFamily]  WITH CHECK ADD  CONSTRAINT [FK_CONTRACT_PRODUCTS_CONTRACT_MASTER] FOREIGN KEY([ContractID])
REFERENCES [dbo].[_KPI_ContractMaster] ([ContractID])
GO

ALTER TABLE [dbo].[_KPI_ContractFamily] CHECK CONSTRAINT [FK_CONTRACT_PRODUCTS_CONTRACT_MASTER]
GO


