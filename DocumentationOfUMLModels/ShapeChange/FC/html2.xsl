<?xml version="1.0" encoding="iso-8859-1"?>
<xsl:stylesheet version="1.0"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
	<!-- (c) 2001-2011 interactive instruments GmbH, Bonn -->
	<xsl:output method="html" />
	<xsl:template match="/">
		<html>
			<head>
				<title>
					Feature Catalogue
					<xsl:value-of select="FeatureCatalogue/name" />
				</title>
				<style type="text/css">
				body
				{
				background-color:#f4f6fe;
				}
				h1
				{
				font-family:Arial, Helvetica, sans-serif;
				font-size:24px;
				color:#151B8D;
				text-align:center;
				}
				h2, h3, h4
				{
				font-family:Arial, Helvetica, sans-serif;
				color:#151B8D;
				}
				p, li
				{
				font-family:Arial, Helvetica, sans-serif;
				font-size:12px;
				margin-top: 0px;
				margin-bottom: 4px;
				}
				.rightalign
				{
				font-size:10px;
				text-align:right;
				}
				.small
				{
				font-size:10px;
				}
				table.att
				{
				font-family:Arial, Helvetica, sans-serif;
				width:100%;
				border-style:none;
				border-collapse:collapse;
				border:0px;
				padding:0px;
				}
				table.link
				{
				font-family:Arial, Helvetica, sans-serif;
				width:100%;
				border-style:none;
				border-collapse:collapse;
				border:0px;
				padding:0px;
				}
				table.overview
				{
				font-family:Arial, Helvetica, sans-serif;
				border-style:none;
				border-collapse:collapse;
				border:0px;
				padding:0px;
				}
				table
				{
				font-family:Arial, Helvetica, sans-serif;
				border-collapse:collapse;
				border:1px solid #98bf21;
				padding:2px 2px 2px 2px;
				}
				tr
				{
				vertical-align:top;
				}
				td.feature, td.values, td.overview
				{
				border:1px solid #98bf21;
				padding:2px 2px 2px 2px;
				}
				p.title2
				{
				font-size:12px;
				font-weight:bold;
				font-family:Arial, Helvetica, sans-serif;
				}
				p.title 
				{
				font-size:14px;
				font-weight:bold;
				font-family:Arial, Helvetica, sans-serif;
				}
				</style>
			</head>
			<body>
				<h1>
					Feature Catalogue
					<xsl:value-of select="FeatureCatalogue/name" />
				</h1>
				<p>
					<b>Version:</b>
				</p>
				<p style="margin-left:20px">
					<xsl:value-of select="FeatureCatalogue/versionNumber" />
				</p>
				<p>
					<b>Date:</b>
				</p>
				<p style="margin-left:20px">
					<xsl:value-of select="FeatureCatalogue/versionDate" />
				</p>
				<p>
					<b>Scope:</b>
				</p>
				<p style="margin-left:20px">
					<xsl:value-of select="FeatureCatalogue/scope" />
				</p>
				<p>
					<b>Responsible organisation:</b>
				</p>
				<p style="margin-left:20px">
					<xsl:value-of select="FeatureCatalogue/producer" />
				</p>

				<a>
					<xsl:attribute name="name">overview</xsl:attribute>
					<h2>Table of contents</h2>
				</a>
				<table class="overview" border="0">
					<xsl:for-each
						select="FeatureCatalogue/Package|FeatureCatalogue/ApplicationSchema">
						<xsl:sort select="./code" />
						<xsl:sort select="./name" />
						<xsl:apply-templates select="." mode="overview"/>
					</xsl:for-each>
				</table>
				<xsl:for-each
					select="FeatureCatalogue/Package|FeatureCatalogue/ApplicationSchema">
					<xsl:sort select="./code" />
					<xsl:sort select="./name" />
					<xsl:apply-templates select="." mode="detail"/>
				</xsl:for-each>
			</body>
		</html>
	</xsl:template>
	<xsl:template match="Package|ApplicationSchema" mode="overview">
						<xsl:variable name="package" select="." />
						<xsl:if test="/FeatureCatalogue/FeatureType/package[attribute::idref=$package/@id]|/FeatureCatalogue/Package/parent[attribute::idref=$package/@id]">
							<div>
								<tr border="0">
									<td class="package" border="0">
										<xsl:choose>
											<xsl:when test="parent">
												<p>
												<b>
													<xsl:text>Package: </xsl:text>
													<a>
														<xsl:attribute name="href">#<xsl:value-of
															select="@id" /></xsl:attribute>
														<xsl:value-of select="name" />
													</a>
												</b>
												</p>
												<p style="margin-left:20px">
												<xsl:text>Parent: </xsl:text>
												<a>
													<xsl:attribute name="href">#<xsl:value-of
														select="parent/@idref" /></xsl:attribute>
													<xsl:value-of select="//ApplicationSchema[@id=$package/parent/@idref]/name" />
												</a>
												</p>
											</xsl:when>
											<xsl:otherwise>
												<p>
												<b>
													<xsl:text>Application Schema: </xsl:text>
													<a>
														<xsl:attribute name="href">#<xsl:value-of
															select="@id" /></xsl:attribute>
														<xsl:value-of select="name" />
													</a>
												</b>
												</p>
											</xsl:otherwise>
										</xsl:choose>
									</td>
									<td class="package" border="0"/>
								</tr>
								<xsl:for-each
									select="/FeatureCatalogue/FeatureType[package/@idref=$package/@id]">
									<xsl:sort select="./code" />
									<xsl:sort select="./name" />
									<xsl:variable name="featuretype" select="." />
									<tr border="0">
										<td class="type" border="0">
											<p style="margin-left:20px">
											<a>
												<xsl:attribute name="href">#<xsl:value-of
													select="$featuretype/@id" /></xsl:attribute>
												<xsl:value-of select="$featuretype/name" />
											</a>
											</p>
										</td>
										<td border="0">
											<p>
											<xsl:value-of select="$featuretype/type" />
											</p>
										</td>
									</tr>
								</xsl:for-each>
							</div>
						</xsl:if>	
	</xsl:template>
	<xsl:template match="Package|ApplicationSchema" mode="detail">

					<xsl:variable name="package" select="." />
					<xsl:if test="/FeatureCatalogue/FeatureType/package[attribute::idref=$package/@id]|/FeatureCatalogue/Package/parent[attribute::idref=$package/@id]">
						<hr />
						<h2>
							<a>
								<xsl:attribute name="name">
            <xsl:value-of select="@id" />
          </xsl:attribute>
								<xsl:choose>
									<xsl:when test="count($package/parent)=1">
										<xsl:text>Package: </xsl:text>
									</xsl:when>
									<xsl:otherwise>
										<xsl:text>Application Schema: </xsl:text>
									</xsl:otherwise>
								</xsl:choose>
								<xsl:value-of select="name" />
							</a>
						</h2>
						<div>
							<xsl:if test="definition">
								<p>
									<b>Definition</b>
								</p>
								<xsl:for-each select="definition">
									<p style="margin-left:20px">
										<xsl:value-of select="." />
									</p>
								</xsl:for-each>
							</xsl:if>
							<xsl:if test="description">
								<p>
									<b>Description</b>
								</p>
								<xsl:for-each select="description">
									<p style="margin-left:20px">
										<xsl:value-of select="." />
									</p>
								</xsl:for-each>
							</xsl:if>
							<xsl:if test="versionNumber">
								<p>
									<b>Version:</b>
								</p>
								<p style="margin-left:20px">
									<xsl:value-of select="versionNumber" />
								</p>
							</xsl:if>
							<xsl:if test="versionDate">
								<p>
									<b>Date:</b>
								</p>
								<p style="margin-left:20px">
									<xsl:value-of select="versionDate" />
								</p>
							</xsl:if>
							<xsl:if test="producer">
								<p>
									<b>Responsible organisation:</b>
								</p>
								<p style="margin-left:20px">
									<xsl:value-of select="producer" />
								</p>
							</xsl:if>
						</div>
						<div>
							<xsl:variable name="nft2" select="count(diagram)" />
							<xsl:if test="$nft2 >= 1">
								<p>
									<b>
										<a>
											<xsl:attribute name="href"><xsl:value-of
												select="diagram/@src" /></xsl:attribute>
											Diagramm
										</a>
									</b>
								</p>
							</xsl:if>
						</div>
						<table border="0" class="link">
							<tr border="0">
								<td width="100%" border="0">
									<p align="right" class="small">
											<a href="#overview">back to overview</a>
									</p>
								</td>
							</tr>
						</table>
						<xsl:for-each
							select="/FeatureCatalogue/FeatureType[package/@idref=$package/@id]">
							<xsl:sort select="./code" />
							<xsl:sort select="./name" />
							<xsl:apply-templates select="." mode="detail"/>
						</xsl:for-each>
					</xsl:if>
	</xsl:template>
	<xsl:template match="FeatureType" mode="detail">

							<xsl:variable name="featuretype" select="." />
							<xsl:variable name="package" select="//*[@id=$featuretype/package/@idref]" />
							<br />
							<a>
								<xsl:attribute name="name">
                    <xsl:value-of select="$featuretype/@id" />
                  </xsl:attribute>
									<h3>
										<xsl:if test="$featuretype/type"><xsl:value-of select="$featuretype/type" />: </xsl:if>
										<xsl:value-of select="$featuretype/name" />
                  </h3>
              </a>
								<table class="feature">
									<tr>
										<td colspan="4" class="feature">
											<p class="title">
													<xsl:value-of select="$featuretype/name" />
											</p>
										</td>
									</tr>

								<xsl:call-template name="entry">
									<xsl:with-param name="title">Definition</xsl:with-param>
									<xsl:with-param name="lines" select="$featuretype/definition"/>
								</xsl:call-template>

								<xsl:call-template name="entry">
									<xsl:with-param name="title">Description</xsl:with-param>
									<xsl:with-param name="lines" select="$featuretype/description"/>
								</xsl:call-template>
								
								<xsl:call-template name="entry">
									<xsl:with-param name="title">Subtype of</xsl:with-param>
									<xsl:with-param name="lines" select="$featuretype/subtypeOf"/>
								</xsl:call-template>

								<xsl:call-template name="entry">
									<xsl:with-param name="title">Type</xsl:with-param>
									<xsl:with-param name="lines" select="$featuretype/type"/>
								</xsl:call-template>

								<xsl:call-template name="entry">
									<xsl:with-param name="title">Code</xsl:with-param>
									<xsl:with-param name="lines" select="$featuretype/code"/>
								</xsl:call-template>

							<xsl:apply-templates select="/FeatureCatalogue/FeatureAttribute[@id=$featuretype/characterizedBy/@idref]" mode="detail"/>

							<xsl:apply-templates select="/FeatureCatalogue/RelationshipRole[@id=$featuretype/characterizedBy/@idref]" mode="detail"/>

<!--
							<xsl:apply-templates select="/FeatureCatalogue/FeatureOperation[@id=$featuretype/characterizedBy/@idref]" mode="detail"/>
-->	
						
								<xsl:call-template name="entry">
									<xsl:with-param name="title">Constraints</xsl:with-param>
									<xsl:with-param name="lines" select="$featuretype/constraint"/>
								</xsl:call-template>

								</table>

							<table border="0" class="link">
								<tr border="0">
									<td width="100%" border="0">
										<p align="right" class="small">
												<a>
													<xsl:attribute name="href">#<xsl:value-of
														select="$package/@id" /></xsl:attribute>
													back to package:
													<xsl:value-of select="$package/name" />
												</a>
										</p>
									</td>
								</tr>
							</table>
							
	</xsl:template>							
							
	<xsl:template match="FeatureAttribute" mode="detail">
									<xsl:variable name="featureAtt" select="." />
									<tr>
										<td colspan="4" class="feature">
											<p class="title2">Attribute:</p>
											<table class="att">
												<xsl:call-template name="attentry">
													<xsl:with-param name="title">Name</xsl:with-param>
													<xsl:with-param name="lines" select="$featureAtt/name"/>
												</xsl:call-template>
												<xsl:call-template name="attentry">
													<xsl:with-param name="title">Definition</xsl:with-param>
													<xsl:with-param name="lines" select="$featureAtt/definition"/>
												</xsl:call-template>
												<xsl:call-template name="attentry">
													<xsl:with-param name="title">Description</xsl:with-param>
													<xsl:with-param name="lines" select="$featureAtt/description"/>
												</xsl:call-template>
												<xsl:call-template name="attentry">
													<xsl:with-param name="title">Voidable</xsl:with-param>
													<xsl:with-param name="lines" select="$featureAtt/voidable"/>
												</xsl:call-template>
												<xsl:call-template name="attentry">
													<xsl:with-param name="title">Code</xsl:with-param>
													<xsl:with-param name="lines" select="$featureAtt/code"/>
												</xsl:call-template>
												<xsl:call-template name="attentry">
													<xsl:with-param name="title">Multiplicity</xsl:with-param>
													<xsl:with-param name="lines" select="$featureAtt/cardinality"/>
												</xsl:call-template>
												<xsl:call-template name="attentry">
													<xsl:with-param name="title">Value type</xsl:with-param>
													<xsl:with-param name="lines" select="$featureAtt/ValueDataType"/>
												</xsl:call-template>
												<xsl:if test="$featureAtt/ValueDomainType = 1">
													<xsl:call-template name="clentry">
													<xsl:with-param name="title">Values</xsl:with-param>
														<xsl:with-param name="values" select="/FeatureCatalogue/Value[@id=$featureAtt/enumeratedBy/@idref]"/>
													</xsl:call-template>
												</xsl:if>											
											</table>
										</td>
									</tr>
									

</xsl:template>

	<xsl:template match="RelationshipRole" mode="detail">
									<xsl:variable name="featureAtt" select="." />
									<tr>
										<td colspan="4" class="feature">
											<p class="title2">Association role:</p>
											<table class="att">
												<xsl:call-template name="attentry">
													<xsl:with-param name="title">Name</xsl:with-param>
													<xsl:with-param name="lines" select="$featureAtt/name"/>
												</xsl:call-template>
												<xsl:call-template name="attentry">
													<xsl:with-param name="title">Definition</xsl:with-param>
													<xsl:with-param name="lines" select="$featureAtt/definition"/>
												</xsl:call-template>
												<xsl:call-template name="attentry">
													<xsl:with-param name="title">Description</xsl:with-param>
													<xsl:with-param name="lines" select="$featureAtt/description"/>
												</xsl:call-template>
												<xsl:call-template name="attentry">
													<xsl:with-param name="title">Voidable</xsl:with-param>
													<xsl:with-param name="lines" select="$featureAtt/voidable"/>
												</xsl:call-template>
												<xsl:call-template name="attentry">
													<xsl:with-param name="title">Code</xsl:with-param>
													<xsl:with-param name="lines" select="$featureAtt/code"/>
												</xsl:call-template>
												<xsl:call-template name="attentry">
													<xsl:with-param name="title">Multiplicity</xsl:with-param>
													<xsl:with-param name="lines" select="$featureAtt/cardinality"/>
												</xsl:call-template>
												<xsl:call-template name="attentry">
													<xsl:with-param name="title">Value type</xsl:with-param>
													<xsl:with-param name="lines" select="$featureAtt/FeatureTypeIncluded"/>
												</xsl:call-template>
											</table>
										</td>
									</tr>
									

</xsl:template>

<!--

								<xsl:for-each
									select="/FeatureCatalogue/FeatureOperation[attribute::id=$featuretype/characterizedBy/@idref]">
									<xsl:variable name="featureOpr" select="." />
									<a>
										<xsl:attribute name="name">
                              <xsl:value-of select="$featuretype/@id" />-<xsl:value-of
											select="$featureOpr/@id" />
                            </xsl:attribute>
										<table>
											<tr>
												<td width="100%" bgcolor="#F0F0F0">
													<b>
														Operation:
														<xsl:value-of select="$featureOpr/name" />
													</b>
													<xsl:if test="$featureOpr/lastChange">
														<xsl:text> </xsl:text>
														<small>
															<font color="red">
																<b>
																	Changed:
																	<xsl:value-of select="$featureOpr/lastChange" />
																</b>
															</font>
														</small>
													</xsl:if>
												</td>
												<td>
													<br />
												</td>
											</tr>
										</table>
									</a>

									<xsl:if test="$featureOpr/definition">
										<p>
											<b>Definition:</b>
										</p>
										<xsl:for-each select="$featureOpr/definition">
											<p style="margin-left:20px">
												<xsl:value-of select="." />
											</p>
										</xsl:for-each>
									</xsl:if>
									<xsl:if test="$featureOpr/description">
										<p>
											<b>Description:</b>
										</p>
										<xsl:for-each select="$featureOpr/description">
											<p style="margin-left:20px">
												<xsl:value-of select="." />
											</p>
										</xsl:for-each>
									</xsl:if>

									<table>
										<tr>
											<td width="100%">
												<p align="right">
													<small>
														<a>
															<xsl:attribute name="href">#<xsl:value-of
																select="$featuretype/@id" /></xsl:attribute>
															back to:
															<xsl:value-of select="$featuretype/name" />
														</a>
													</small>
												</p>
											</td>
											<td>
												<br />
											</td>
										</tr>
									</table>
								</xsl:for-each>
-->

	<xsl:template name="entry">
		<xsl:param name="title"/>
		<xsl:param name="lines"/>
								<xsl:if test="$lines">
									<tr>
										<td colspan="4" class="feature">
											<p class="title2"><xsl:value-of select="$title" />:</p>
											<xsl:for-each select="$lines">
												<xsl:variable name="line" select="." />
												<xsl:choose>
													<xsl:when
														test="$line/@idref and //*[@id=$line/@idref]">
														<p style="margin-left:20px">
															<a>
																<xsl:attribute name="href">#<xsl:value-of
																	select="./@idref" /></xsl:attribute>
																<xsl:value-of select="." />
															</a>
														</p>
													</xsl:when>
													<xsl:otherwise>
														<p style="margin-left:20px">
															<xsl:value-of select="." />
														</p>
													</xsl:otherwise>
												</xsl:choose>
											</xsl:for-each>
										</td>
									</tr>
								</xsl:if>
	</xsl:template>

	<xsl:template name="attentry">
		<xsl:param name="title"/>
		<xsl:param name="lines"/>
								<xsl:if test="$lines">
									<tr border="0">
										<td width="100px" border="0">
											<p class="title2" style="margin-left:18px"><xsl:value-of select="$title" />:</p>
										</td>
										<td border="0">
											<xsl:for-each select="$lines">
												<xsl:variable name="line" select="." />
												<xsl:choose>
													<xsl:when
														test="$line/@idref and //*[@id=$line/@idref]">
														<p>
															<a>
																<xsl:attribute name="href">#<xsl:value-of
																	select="./@idref" /></xsl:attribute>
																<xsl:value-of select="." />
																<xsl:if test="$line/@category"><xsl:text> </xsl:text>(<xsl:value-of select="./@category" />)</xsl:if>
															</a>
														</p>
													</xsl:when>
													<xsl:otherwise>
														<p>
															<xsl:value-of select="." />
															<xsl:if test="$line/@category"><xsl:text> </xsl:text>(<xsl:value-of select="./@category" />)</xsl:if>
														</p>
													</xsl:otherwise>
												</xsl:choose>
											</xsl:for-each>
										</td>
									</tr>
								</xsl:if>
	</xsl:template>

	<xsl:template name="clentry">
		<xsl:param name="title"/>
		<xsl:param name="values"/>
								<xsl:if test="$values">
									<tr border="0">
										<td width="100px" border="0">
											<p class="title2" style="margin-left:18px">Values:</p>
										</td>
										<td border="0">
											<table class="values">
												<xsl:for-each select="$values">
												<tr>
													<xsl:variable name="value" select="." />
													<td class="values">
													<p>
														<xsl:value-of select="./label" />
													</p>
													</td>
													<td class="values">
													<xsl:if test="./definition">
														<xsl:for-each select="./definition">
															<p class="small">
																<xsl:value-of select="." />
															</p>
														</xsl:for-each>
													</xsl:if>
													<xsl:if test="./description">
														<xsl:for-each select="./description">
															<p class="small">
																<xsl:value-of select="." />
															</p>
														</xsl:for-each>
													</xsl:if>
													</td>
												</tr>
												</xsl:for-each>
											</table>
										</td>
									</tr>
								</xsl:if>
	</xsl:template>
		
</xsl:stylesheet>
