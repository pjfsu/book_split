<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:output version="1.0" method="text" omit-xml-declaration="yes" encoding="UTF-8" indent="yes"/>

<!-- main -->
<xsl:template match="/">
	<xsl:apply-templates select="//chapter"/>
</xsl:template>

<!-- from <= to <= pages -->
<xsl:template match="chapter[(@from &lt;= @to) and (@to &lt;= //@pages)]">
	<!-- from,to,name -->
	<xsl:value-of select="@from"/>
	<xsl:text>,</xsl:text>
	<xsl:value-of select="@to"/>
	<xsl:text>,</xsl:text>
	<xsl:value-of select="@name"/>
	<xsl:text>&#xa;</xsl:text> <!-- new line -->
</xsl:template>

</xsl:stylesheet> 
