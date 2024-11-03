<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:output version="1.0" method="text" omit-xml-declaration="yes" encoding="UTF-8" indent="yes"/>

<!-- main -->
<xsl:template match="/">
	<xsl:text># BEGIN OF PDFBOX SCRIPT</xsl:text>
	<xsl:text>&#xa;</xsl:text> <!-- new line -->

	<!-- printf 'generated pdfs will be saved in "%s"\n' "OUTDIR" -->
	<xsl:text>printf 'generated pdfs will be saved in "%s"\n' "</xsl:text>
	<xsl:value-of select="//@outdir"/>
	<xsl:text>"</xsl:text>
	<xsl:text>&#xa;</xsl:text> <!-- new line -->
	
	<!-- ! [ -d "OUTDIR" ] && mkdir "OUTDIR" -->
	<xsl:text>! [ -d "</xsl:text>
	<xsl:value-of select="//@outdir"/>
	<xsl:text>" ] &amp;&amp; mkdir "</xsl:text>
	<xsl:value-of select="//@outdir"/>
	<xsl:text>"</xsl:text>
	<xsl:text>&#xa;</xsl:text> <!-- new line -->

	<xsl:apply-templates select="//chapter"/>

	<xsl:text># END OF PDFBOX SCRIPT</xsl:text>
	<xsl:text>&#xa;</xsl:text> <!-- new line -->
</xsl:template>

<!-- from <= to <= pages -->
<xsl:template match="chapter[(@from &lt;= @to) and (@to &lt;= //@pages)]">
	<!-- # CHAPTER "NAME" -->
	<xsl:text># CHAPTER "</xsl:text>
	<xsl:value-of select="@name"/>
	<xsl:text>"</xsl:text>
	<xsl:text>&#xa;</xsl:text> <!-- new line -->

	<!-- printf 'generating "%s.pdf" ...\n' "CHAPTER" -->
	<xsl:text>printf 'generating "%s.pdf" ... ' "</xsl:text>
	<xsl:value-of select="@name"/>
	<xsl:text>"</xsl:text>
	<xsl:text>&#xa;</xsl:text> <!-- new line -->

	<!-- java -jar PDFBOX_APP_JAR split \ -->
	<!--  -startPage=FROM \ -->
	<!--  -endPage=TO \ -->
	<!--  -i="BOOK" \ -->
	<!--  -outputPrefix="OUTDIR/CHAPTER" -->
	<xsl:text>java -jar </xsl:text>
	<xsl:value-of select="//@pdfbox_app_jar"/>
	<xsl:text> split \</xsl:text>
	<xsl:text>&#xa;</xsl:text> <!-- new line -->
	<xsl:text> -startPage=</xsl:text>
	<xsl:value-of select="@from"/>
	<xsl:text> \</xsl:text>
	<xsl:text>&#xa;</xsl:text> <!-- new line -->
	<xsl:text> -endPage=</xsl:text>
	<xsl:value-of select="@to"/>
	<xsl:text> \</xsl:text>
	<xsl:text>&#xa;</xsl:text> <!-- new line -->
	<xsl:text> -i="</xsl:text>
	<xsl:value-of select="//book/@name"/>
	<xsl:text>" \</xsl:text>
	<xsl:text>&#xa;</xsl:text> <!-- new line -->
	<xsl:text> -outputPrefix="</xsl:text>
	<xsl:value-of select="//@outdir"/>
	<xsl:text>/</xsl:text>
	<xsl:value-of select="@name"/>
	<xsl:text>"</xsl:text>
	<xsl:text>&#xa;</xsl:text> <!-- new line -->

	<!-- mv "CHAPTER-1.pdf" \ -->
	<!--  "CHAPTER.pdf" -->
	<xsl:text>mv "</xsl:text>
	<xsl:value-of select="//@outdir"/>
	<xsl:text>/</xsl:text>
	<xsl:value-of select="@name"/>
	<xsl:text>-1.pdf" \</xsl:text>
	<xsl:text>&#xa;</xsl:text> <!-- new line -->
	<xsl:text> "</xsl:text>
	<xsl:value-of select="//@outdir"/>
	<xsl:text>/</xsl:text>
	<xsl:value-of select="@name"/>
	<xsl:text>.pdf"</xsl:text>
	<xsl:text>&#xa;</xsl:text> <!-- new line -->
	
	<!-- printf "done!\n" -->
	<xsl:text>printf 'done!\n'</xsl:text>
	<xsl:text>&#xa;</xsl:text> <!-- new line -->
</xsl:template>

<!-- not(from <= to <= pages) -->
<xsl:template match="chapter[not((@from &lt;= @to) and (@to &lt;= //@pages))]">
	<!-- # INVALID CHAPTER "NAME" -->
	<xsl:text># INVALID CHAPTER "</xsl:text>
	<xsl:value-of select="@name"/>
	<xsl:text>"</xsl:text>
	<xsl:text>&#xa;</xsl:text> <!-- new line -->

	<!-- printf 'invalid chapter "%s" because from=%i is greater than to=%i or to=%i is greater than book pages=%i\n' \ -->
	<!--  "NAME" FROM TO TO PAGES -->
	<xsl:text>printf 'invalid chapter "%s" because from=%i is greater than to=%i or to=%i is greater than book pages=%i\n' \</xsl:text>
	<xsl:text>&#xa;</xsl:text> <!-- new line -->
	<xsl:text> "</xsl:text>
	<xsl:value-of select="@name"/>
	<xsl:text>" </xsl:text>
	<xsl:value-of select="@from"/>
	<xsl:text> </xsl:text>
	<xsl:value-of select="@to"/>
	<xsl:text> </xsl:text>
	<xsl:value-of select="@to"/>
	<xsl:text> </xsl:text>
	<xsl:value-of select="//@pages"/>
	<xsl:text>&#xa;</xsl:text> <!-- new line -->
</xsl:template>

</xsl:stylesheet> 
