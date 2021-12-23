<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<!-- stations_clean.xslt - Fix known issues with data coming from WMO.
     Copyright (C) 2021  Pierre Choffet

     This program is free software: you can redistribute it and/or modify
     it under the terms of version 3 of the GNU General Public License as
     published by the Free Software Foundation.

     This program is distributed in the hope that it will be useful,
     but WITHOUT ANY WARRANTY; without even the implied warranty of
     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
     GNU General Public License for more details.

     You should have received a copy of the GNU General Public License
     along with this program.  If not, see <http://www.gnu.org/licenses/>.
     -->
	<xsl:output method="xml" encoding="utf-8" />

	<!-- List known invalid WIGOS IDs in original data -->
	<xsl:variable name="wigos-ids">
		<wigos-id invalid-value="41247" />
		<wigos-id invalid-value="72388" />
		<wigos-id invalid-value="0-634-0000-0000" />
		<wigos-id invalid-value="0-858-02560-COL" />
		<wigos-id invalid-value="1-620-2001-0507" />
		<wigos-id invalid-value="NaN-NaN-NaN-undefined" />
	</xsl:variable>
	
	<xsl:param name="hardcoded-wigos-id" select="document('')/*/xsl:variable[@name='wigos-ids']/*"/>
	
	<xsl:template match="node()|@*">
		<xsl:copy>
			<xsl:apply-templates select="node()|@*" />
		</xsl:copy>
	</xsl:template>
	
	<xsl:template match="station">
		<xsl:copy>
			<xsl:apply-templates select="@*|id|name|region|territory|declaredStatus" />
			
			<!-- Discard coordinates if latitude or longitude are not accurate enough -->
			<xsl:if test="contains(latitude, '.') and contains(longitude, '.')">
				<xsl:apply-templates select="latitude|longitude" />
			</xsl:if>
			
			<xsl:apply-templates select="elevation|stationTypeName|wigosStationIdentifiers|wigosId|stationTypeId|dateEstablished|dateClosed|stationStatusCode|stationTypeCode|stationProgramsDeclaredStatuses" />
		</xsl:copy>
	</xsl:template>
	
	<!-- Remove invalid WIGOS identifiers -->
	<xsl:template match="wigosStationIdentifiers">
		<xsl:if test="translate(wigosStationIdentifier, '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-', '') = '' and contains(wigosStationIdentifier, '-') and not($hardcoded-wigos-id[@invalid-value = current()/wigosStationIdentifier])">
			<xsl:copy>
				<xsl:apply-templates select="node()|@*" />
			</xsl:copy>
		</xsl:if>
	</xsl:template>	
	<xsl:template match="wigosId">
		<xsl:if test="translate(., '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-', '') = '' and contains(., '-') and not($hardcoded-wigos-id[@invalid-value = current()])">
			<xsl:copy>
				<xsl:apply-templates select="node()|@*" />
			</xsl:copy>
		</xsl:if>
	</xsl:template>
</xsl:stylesheet>
