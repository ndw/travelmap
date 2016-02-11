<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:air="http://nwalsh.com/ns/airports"
                xmlns="http://nwalsh.com/ns/airports"
		exclude-result-prefixes="xs air"
                version="2.0">

<xsl:output method="xml" encoding="utf-8" indent="yes"
	    omit-xml-declaration="yes"/>

<xsl:strip-space elements="*"/>

<xsl:template match="/air:airports">
  <xsl:apply-templates select="air:airport"/>
</xsl:template>

<xsl:template match="air:airport">
  <xsl:if test="air:iata_code != ''">
    <xsl:result-document href="data/{air:id}.xml" method="xml">
      <xsl:copy>
        <xsl:apply-templates select="@*,node()"/>
      </xsl:copy>
    </xsl:result-document>
  </xsl:if>
</xsl:template>

<xsl:template match="element()">
  <xsl:copy>
    <xsl:apply-templates select="@*,node()"/>
  </xsl:copy>
</xsl:template>

<xsl:template match="attribute()|text()|comment()|processing-instruction()">
  <xsl:copy/>
</xsl:template>

</xsl:stylesheet>
