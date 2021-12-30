<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:wdef="https://purl.choffet.net/wdef">
<!-- generate_wdef.xslt - Convert XML stations into WDEF.
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
	<xsl:output indent="yes" method="xml" encoding="utf-8" />
	
	<xsl:param name="document-hardcoded-territories" select="document('../hardcoded/territories.xml')" />
	
	<xsl:key name="hardcoded-territory-wmo-name" match="/territories/territory" use="@wmo-name" />
	
	<xsl:template match="text()" />
	
	<xsl:template match="stations">
		<wdef:knowledge xmlns:wdef="https://purl.choffet.net/wdef">
			<!--
			  NOTE: Stations with dateClosed are excluded for now because labels
			        contain the name the country they belongs to. Since we have no
			        historical information in WMO database, we cannot ensure we use
			        the good name/P17 reference without our own country list.
			-->
			<xsl:apply-templates select="station[wigosStationIdentifiers/wigosStationIdentifier and not(dateClosed)]" />
		</wdef:knowledge>
	</xsl:template>
	
	<xsl:template match="station">
		<xsl:variable name="territory-name">
			<xsl:value-of select="territory" />
		</xsl:variable>
		<xsl:variable name="station-name-lang">
			<xsl:for-each select="$document-hardcoded-territories">
				<xsl:value-of select="key('hardcoded-territory-wmo-name', $territory-name)/@stations-name-lang" />
			</xsl:for-each>
		</xsl:variable>
		
		<xsl:if test="$station-name-lang = 'en' or $station-name-lang = 'es' or $station-name-lang = 'sq'">
			<xsl:variable name="element-id">
				<xsl:text>?E</xsl:text>
				<xsl:value-of select="id" />
			</xsl:variable>
			
			<wdef:element>
				<xsl:attribute name="wdef:id">
					<xsl:value-of select="$element-id" />
				</xsl:attribute>
				<xsl:apply-templates select="." mode="station-label">
					<xsl:with-param name="station-name-lang" select="$station-name-lang" />
				</xsl:apply-templates>
				<xsl:apply-templates select="." mode="station-descriptions" />
				<wdef:property wdef:pid="P31">
					<xsl:attribute name="wdef:id">
						<xsl:text>?P31-</xsl:text>
						<xsl:value-of select="$element-id" />
					</xsl:attribute>
					<wdef:value>
						<xsl:attribute name="wdef:id">
							<xsl:text>?V1-P31-</xsl:text>
							<xsl:value-of select="$element-id" />
						</xsl:attribute>
						<wdef:ref-element>Q190107</wdef:ref-element>
					</wdef:value>
				</wdef:property>
				<xsl:apply-templates select="territory">
					<xsl:with-param name="element-id" select="$element-id" />
				</xsl:apply-templates>
				<xsl:if test="contains(latitude, '.') and contains(longitude, '.')">
					<wdef:property wdef:pid="P625">
						<xsl:attribute name="wdef:id">
							<xsl:text>?P625-</xsl:text>
							<xsl:value-of select="$element-id" />
						</xsl:attribute>
						<wdef:value>
							<xsl:attribute name="wdef:id">
								<xsl:text>?V1-P625-</xsl:text>
								<xsl:value-of select="$element-id" />
							</xsl:attribute>
							<wdef:coordinate>
								<xsl:variable name="precision-latitude">
									<xsl:call-template name="coord-precision">
										<xsl:with-param name="coord" select="latitude" />
									</xsl:call-template>
								</xsl:variable>
								<xsl:variable name="precision-longitude">
									<xsl:call-template name="coord-precision">
										<xsl:with-param name="coord" select="longitude" />
									</xsl:call-template>
								</xsl:variable>
								<xsl:attribute name="wdef:latitude">
									<xsl:value-of select="latitude" />
								</xsl:attribute>
								<xsl:attribute name="wdef:longitude">
									<xsl:value-of select="longitude" />
								</xsl:attribute>
								<xsl:attribute name="wdef:precision">
									<xsl:choose>
										<xsl:when test="$precision-latitude > $precision-longitude">
											<xsl:value-of select="$precision-longitude" />
										</xsl:when>
										<xsl:otherwise>
											<xsl:value-of select="$precision-latitude" />
										</xsl:otherwise>
									</xsl:choose>
								</xsl:attribute>
								<wdef:ref-element>Q2</wdef:ref-element>
							</wdef:coordinate>
						</wdef:value>
					</wdef:property>
				</xsl:if>
				<xsl:apply-templates select="elevation">
					<xsl:with-param name="element-id" select="$element-id" />
				</xsl:apply-templates>
				<xsl:if test="wigosStationIdentifiers/wigosStationIdentifier">
					<wdef:property wdef:pid="P4136">
						<xsl:attribute name="wdef:id">
							<xsl:text>?P4136-</xsl:text>
							<xsl:value-of select="$element-id" />
						</xsl:attribute>
						<xsl:apply-templates select="wigosStationIdentifiers/wigosStationIdentifier">
							<xsl:with-param name="element-id" select="$element-id" />
						</xsl:apply-templates>
					</wdef:property>
				</xsl:if>
				<xsl:apply-templates select="dateEstablished">
					<xsl:with-param name="element-id" select="$element-id" />
				</xsl:apply-templates>
				<xsl:apply-templates select="dateClosed">
					<xsl:with-param name="element-id" select="$element-id" />
				</xsl:apply-templates>
			</wdef:element>
		</xsl:if>
	</xsl:template>
	
	<xsl:template match="station" mode="station-label">
		<xsl:param name="station-name-lang" />
		
		<wdef:label>
			<xsl:attribute name="wdef:interface-lang">
				 <xsl:value-of select="$station-name-lang" />
			</xsl:attribute>
			<xsl:call-template name="camel-case">
				<xsl:with-param name="text" select="name" />
			</xsl:call-template>
		</wdef:label>
	</xsl:template>
	
	<xsl:template match="station" mode="station-descriptions">
		<xsl:variable name="territory" select="territory" />
		<wdef:description wdef:interface-lang="en">
			<xsl:text>weather station </xsl:text>
			<xsl:for-each select="$document-hardcoded-territories">
				<xsl:value-of select="key('hardcoded-territory-wmo-name', $territory)/@prefix-en" />
				<xsl:text> </xsl:text>
				<xsl:value-of select="key('hardcoded-territory-wmo-name', $territory)/@name-en" />
			</xsl:for-each>
		</wdef:description>
		<wdef:description wdef:interface-lang="fr">
			<xsl:text>station météorologique </xsl:text>
			<xsl:for-each select="$document-hardcoded-territories">
				<xsl:value-of select="key('hardcoded-territory-wmo-name', $territory)/@prefix-fr" />
				<xsl:if test="key('hardcoded-territory-wmo-name', $territory)/@prefix-fr != 'à l’'">
					<xsl:text> </xsl:text>
				</xsl:if>
				<xsl:value-of select="key('hardcoded-territory-wmo-name', $territory)/@name-fr" />
			</xsl:for-each>
		</wdef:description>
	</xsl:template>
	
	<xsl:template match="territory">
		<xsl:param name="element-id" />
		
		<xsl:variable name="territory-name">
			<xsl:value-of select="." />
		</xsl:variable>
		<xsl:variable name="country-qid">
			<xsl:for-each select="$document-hardcoded-territories">
				<xsl:value-of select="key('hardcoded-territory-wmo-name', $territory-name)/@country-qid" />
			</xsl:for-each>
		</xsl:variable>
		<xsl:if test="$country-qid">
			<wdef:property wdef:pid="P17">
				<xsl:attribute name="wdef:id">
					<xsl:text>?P17-</xsl:text>
					<xsl:value-of select="$element-id" />
				</xsl:attribute>
				<wdef:value>
					<xsl:attribute name="wdef:id">
						<xsl:text>?V1-P17-</xsl:text>
						<xsl:value-of select="$element-id" />
					</xsl:attribute>
					<wdef:ref-element>
						<xsl:value-of select="$country-qid" />
					</wdef:ref-element>
				</wdef:value>
			</wdef:property>
		</xsl:if>
	</xsl:template>
	
	<xsl:template match="elevation">
		<xsl:param name="element-id" />
		
		<wdef:property wdef:pid="P2044">
			<xsl:attribute name="wdef:id">
				<xsl:text>?P2044-</xsl:text>
				<xsl:value-of select="$element-id" />
			</xsl:attribute>
			<wdef:value>
				<xsl:attribute name="wdef:id">
					<xsl:text>?V1-P2044-</xsl:text>
					<xsl:value-of select="$element-id" />
				</xsl:attribute>
				<wdef:quantity wdef:unit="Q11573">
					<xsl:value-of select="." />
				</wdef:quantity>
			</wdef:value>
		</wdef:property>
	</xsl:template>
	
	<xsl:template match="wigosStationIdentifier">
		<xsl:param name="element-id" />
		
		<wdef:value>
			<xsl:attribute name="wdef:id">
				<xsl:text>?V</xsl:text>
				<xsl:value-of select="generate-id(.)" />
				<xsl:text>-P17-</xsl:text>
				<xsl:value-of select="$element-id" />
			</xsl:attribute>
			<wdef:literal>
				<xsl:value-of select="." />
			</wdef:literal>
		</wdef:value>
	</xsl:template>
	
	<xsl:template match="dateEstablished | dateClosed">
		<xsl:param name="element-id" />
		<xsl:variable name="pid">
			<xsl:choose>
				<xsl:when test="name(.) = 'dateEstablished'">
					<xsl:text>P729</xsl:text>
				</xsl:when>
				<xsl:otherwise>
					<xsl:text>P730</xsl:text>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		
		<xsl:variable name="year" select="substring(., 1, 4)" />
		<xsl:variable name="month" select="substring(., 6, 2)" />
		<xsl:variable name="day" select="substring(., 9, 2)" />
		<xsl:variable name="precision">
			<xsl:choose>
				<!-- Last day of year -->
				<xsl:when test="$month = 12 and $day = 31">
					<xsl:text>9</xsl:text>
				</xsl:when>
				<!-- Last day of month -->
				<xsl:when test="($day = 31 and ($month = 1 or $month = 3 or $month = 5 or $month = 7 or $month = 8 or $month = 10)) or ($day = 30 and ($month = 4 or $month = 6 or $month = 9 or $month = 11)) or ($day = 29 and $month = 2 and ($year mod 4) = 0 and ($year mod 1000) != 0) or ($day = 28 and $month = 2 and ($year mod 4) = 0 and ($year mod 1000) = 0) or ($day = 28 and $month = 2 and ($year mod 4) != 0)">
					<xsl:text>10</xsl:text>
				</xsl:when>
				<!-- Any other day -->
				<xsl:otherwise>
					<xsl:text>11</xsl:text>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:variable name="out-year">
			<xsl:choose>
				<xsl:when test="$month = 12 and $day = 31">
					<xsl:value-of select="$year + 1" />
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="$year" />
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:variable name="out-month">
			<xsl:choose>
				<xsl:when test="$day = 31 and $month = 12">
					<xsl:text>01</xsl:text>
				</xsl:when>
				<xsl:when test="($day = 31 and ($month = 1 or $month = 3 or $month = 5 or $month = 7 or $month = 8 or $month = 10)) or ($day = 30 and ($month = 4 or $month = 6 or $month = 9 or $month = 11)) or ($day = 29 and $month = 2 and ($year mod 4) = 0 and ($year mod 1000) != 0) or ($day = 28 and $month = 2 and ($year mod 4) = 0 and ($year mod 1000) = 0) or ($day = 28 and $month = 2 and ($year mod 4) != 0)">
					<xsl:value-of select="format-number($month + 1, '00')" />
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="format-number($month, '00')" />
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:variable name="out-day">
			<xsl:choose>
				<xsl:when test="($day = 31 and ($month = 1 or $month = 3 or $month = 5 or $month = 7 or $month = 8 or $month = 10 or $month = 12)) or ($day = 30 and ($month = 4 or $month = 6 or $month = 9 or $month = 11)) or ($day = 29 and $month = 2 and ($year mod 4) = 0 and ($year mod 1000) != 0) or ($day = 28 and $month = 2 and ($year mod 4) = 0 and ($year mod 1000) = 0) or ($day = 28 and $month = 2 and ($year mod 4) != 0)">
					<xsl:value-of select="format-number(1, '00')" />
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="format-number($day + 1, '00')" />
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		
		<wdef:property>
			<xsl:attribute name="wdef:pid">
				<xsl:value-of select="$pid" />
			</xsl:attribute>
			<xsl:attribute name="wdef:id">
				<xsl:text>?</xsl:text>
				<xsl:value-of select="$pid" />
				<xsl:text>-</xsl:text>
				<xsl:value-of select="$element-id" />
			</xsl:attribute>
			<wdef:value>
				<xsl:attribute name="wdef:id">
					<xsl:text>?V</xsl:text>
					<xsl:value-of select="generate-id(.)" />
					<xsl:text>-</xsl:text>
					<xsl:value-of select="$pid" />
					<xsl:text>-</xsl:text>
					<xsl:value-of select="$element-id" />
				</xsl:attribute>
				<wdef:time wdef:calendar="gregorian">
					<xsl:attribute name="wdef:precision">
						<xsl:value-of select="$precision" />
					</xsl:attribute>
					<xsl:text>+</xsl:text>
					<xsl:value-of select="$out-year" />
					<xsl:text>-</xsl:text>
					<xsl:value-of select="$out-month" />
					<xsl:text>-</xsl:text>
					<xsl:value-of select="$out-day" />
					<xsl:text>T12:00:00Z</xsl:text>
				</wdef:time>
			</wdef:value>
		</wdef:property>
	</xsl:template>

	<!-- Camel case -->
	<xsl:template name="camel-case">
		<xsl:param name="text" select="."/>
		<xsl:variable name="uppercase">ABCDEFGHIJKLMNOPQRSTUVWXYZ</xsl:variable>
		<xsl:variable name="lowercase">abcdefghijklmnopqrstuvwxyz</xsl:variable>
		<xsl:variable name="word" select="substring-before(concat($text, ' '), ' ')" />

		<xsl:value-of select="translate(substring($word, 1, 1), $lowercase, $uppercase)" />
		<xsl:value-of select="translate(substring($word, 2), $uppercase, $lowercase)" />

		<xsl:if test="contains($text, ' ')">
			<xsl:text> </xsl:text>
			<xsl:call-template name="camel-case">
				<xsl:with-param name="text" select="substring-after($text, ' ')"/>
			</xsl:call-template>
		</xsl:if>
	</xsl:template>
	
	<xsl:template name="coord-precision">
		<xsl:param name="coord" />
		<xsl:variable name="decimals">
			<xsl:value-of select="string-length(substring-after($coord, '.'))" />
		</xsl:variable>
		
		<xsl:choose>
			<xsl:when test="not(contains($coord, '.'))">
				<xsl:text>1</xsl:text>
			</xsl:when>
			<xsl:when test="$decimals = 1">
				<xsl:text>0.1</xsl:text>
			</xsl:when>
			<xsl:when test="$decimals = 2">
				<xsl:text>0.01</xsl:text>
			</xsl:when>
			<xsl:when test="$decimals >= 3">
				<xsl:text>0.001</xsl:text>
			</xsl:when>
		</xsl:choose>
	</xsl:template>
</xsl:stylesheet>
