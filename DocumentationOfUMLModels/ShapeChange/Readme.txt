Note for configurations:

To ensure that ShapeChange uses Saxon and not Xalan:
<targetParameter name="xslTransformerFactory" value= "net.sf.saxon.TransformerFactoryImpl"/>