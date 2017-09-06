USE [KPI_App]
GO

/****** Object:  UserDefinedFunction [dbo].[_KPI_USOrder]    Script Date: 08/30/2017 15:56:57 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date, ,>
-- Description:	<Description, ,>
-- =============================================
CREATE FUNCTION [dbo].[_KPI_USOrder]
(
	@CoNum CoNumType
)
RETURNS tinyint
AS
BEGIN

declare @ret tinyint
set @ret = 0

	declare @country nvarchar(10)
	select @country = ca.country from co (nolock) join custaddr ca on ca.cust_num = co.cust_num
	if ISNULL(@country,'') = 'USA' set @ret = 1
return @ret
END


GO


