<?xml version="1.0" encoding="UTF-8" ?>
<transform version="1.0" xmlns="http://www.w3.org/1999/XSL/Transform">
<output method="text" encoding="utf-8"/>

<!-- Author: Kent Finley -->
<!-- Purpose: Convert MusicXML file as exported by iReal Pro to JSON format required by SessionBand Jazz Volume 1 -->
<!-- Internet Explorer can act as an XSLT processor - insert reference to this stylesheet (transform) into extracted MusicXML file -->
<!-- e.g. 
     <?xml-stylesheet type="text/xsl" href="C:\Users\username\Desktop\musicxml2sessionbandjazz - 2.0.xsl"?>	 
	    can omit the path and just give the filename, if files in same directory
-->	
<!-- then drag the .xml file to the current address bar in IE, save resulting text (and text ONLY) in a text file with .sbj extension -->
<!-- import .sbj file into SessionBand Jazz Volume 1 via iTunes -->

<!-- NOT suitable for converting files with multiple time signatures, files with more than one note per harmony -->
<!-- only chord charts as exported by iReal Pro, basically -->
<!-- not extracting key signature from MusicXML file, as it doesn't really matter in SessionBand Jazz Volume 1 -->

<!-- assuming there will only be one 'part' to the score, and that measure number 1 will hold the time signature and divisions -->
<!-- exceptions to the above will probably NOT process correctly -->

<variable name="divisions" select="score-partwise/part[1]/measure[1]/attributes/divisions" />
<variable name="beats" select="score-partwise/part[1]/measure[1]/attributes/time/beats" />
<variable name="maxduration" select="$beats * $divisions * 2" />
<variable name="debug" select="true()"/>
<!--  'beat-type' value (time signature denominator) won't be used, but may be helpful in distinguishing between 4 feel and 2 feel signatures
<variable name="beat-type" select="score-partwise/part[1]/measure[1]/attributes/time/beat-type" />
-->

    <template match="score-partwise">
		<text>{"Genre":</text>
		<choose>
			<when test="($beats mod 3 = 0) and ($beats mod 2 != 0)">"Medium 3/4",</when>
			<when test="($beats mod 2 = 0)">"Medium Swing (4 feel)",</when>
			<otherwise>"Bossa Nova",</otherwise>
		</choose>
		<!-- only handling two possibilities for time, those divisible evenly by 3 but not by 2 will result in Medium 3/4 -->
		<!-- whereas those divisible evenly by 2 will result in Medium Swing (4 feel) -->
		<!-- 'odd' time signatures like 5/4, 7/8 MAY have odd results, but converting as Bossa Nova -->
		<!-- COMPLETE list for SessionBand Jazz Vol 1. 
			Ballad
			12/8
			Slow Swing (2 feel)
			Slow Swing (4 feel)
			Medium Swing (2 feel)
			Medium Swing (4 feel)
			Bossa Nova
			Shuffle
			Medium 3/4
			Afro Jazz
			Med Up Swing (2 feel)
			Med Up Swing (4 feel)
			Fast Latin
			Up Swing (2 feel)
			Up Swing (4 feel)
		-->
		<text>"TrackItems":[</text>
		<apply-templates select="part[1]/measure[1]/harmony[1]"/>
		<!-- want only the first occurrence of harmony in the document overall -->
		<!-- doesn't care about position if I don't specify the ancestors -->
		<text>],</text>
		<text>"PlaybackSpeed":1,</text>
		<apply-templates select="identification/creator[@type='composer']"/>
		<text>"TrackComments":[],</text>
		<text>"TrackMixer":</text>
		<text>[{"Level":0.5,"Mute":false,"Solo":false},</text>
		<text>{"Level":0.5,"Mute":false,"Solo":false},</text>
		<text>{"Level":0.5,"Mute":false,"Solo":false},</text>
		<text>{"Level":0.5,"Mute":false,"Solo":false},</text>
		<text>{"Level":0.5,"Mute":true,"Solo":false}],</text>
		<apply-templates select="./movement-title"/>
		<text>}</text>
    </template>

    <template match="identification/creator">
		<text>"TrackAuthor":"</text>
		<apply-templates/>
		<text>",</text>
    </template>

    <template match="movement-title">
		<text>"TrackName":"</text>
		<apply-templates/>
		<text>"</text>
    </template>

	<template match="harmony">
	
		<!-- pains me to say, but think we're going to have to look at 'NEXT' harmonies instead of previous -->
		<!-- have to know when to close the output harmony with correct duration-->
		
		<param name="prevkind">-1</param>
		<param name="prevduration">0</param>
		<param name="prevrootstep">-1</param>
		<param name="prevrootalter">0</param>
				 
		<variable name="curkind" select="kind"/>
		<variable name="curduration" select="following-sibling::note[1]/duration"/>
		<variable name="currootstep" select="root/root-step"/>
		<variable name="currootalter" select="root/root-alter"/>
		
		<variable name="nextkind" select="following::kind"/>
		<variable name="nextduration" select="following::following-sibling::note[1]/duration"/>
		<variable name="nextrootstep" select="following::root/root-step"/>
		<variable name="nextrootalter" select="following::root/root-alter"/>
		
		<variable name="keyvariation">
				<choose>
					<when test="$curkind='major-minor'">8</when> 
					<when test="(starts-with('major',$curkind)) and ('major-minor'=$curkind)">0</when>    
					<when test="starts-with('minor',$curkind)">6</when>    
					<when test="starts-with('dominant',$curkind)">2</when>    
					<!--but there can be many alterations of the dominant, depending on 'degree'-->
					<when test="$curkind='augmented'">4</when>    
					<!-- not really quite right, mapping to dom7#5#9-->
					<when test="starts-with('diminished',$curkind)">9</when>    
					<!-- but diminished could also be entered as m(7)b5 in iReal Pro -->
					<when test="$curkind='half-diminished'">7</when>    
					<otherwise>0</otherwise>
					<!-- ideally to be derived from 'kind' AND 'degree' (for alterations of the basic harmonies) -->
					<!-- types in SessionBand Jazz Volume 1: 
							0=maj7(9)
							1=maj7#11  - altered
							2=7(13)
							3=7(b9) - altered
							4=7(#5#9) - altered
							5=7sus(13) 
							6=m7(9)
							7=m7(b5) i.e. half-diminished
							8=m(maj7)
							9=dim
					-->
				</choose>
		</variable>
		
		<variable name="keyvalue">
			<choose>
				   <when test="$currootstep='C'"><value-of select="(0+$currootalter+12) mod 12"/></when>
				   <when test="$currootstep='D'"><value-of select="(2+$currootalter+12) mod 12"/></when>
				   <when test="$currootstep='E'"><value-of select="(4+$currootalter+12) mod 12"/></when>
				   <when test="$currootstep='F'"><value-of select="(5+$currootalter+12) mod 12"/></when>
				   <when test="$currootstep='G'"><value-of select="(7+$currootalter+12) mod 12"/></when>
				   <when test="$currootstep='A'"><value-of select="(9+$currootalter+12) mod 12"/></when>
				   <when test="$currootstep='B'"><value-of select="(11+$currootalter+12) mod 12"/></when>
			</choose>
		</variable>
		
		<choose>
			<when test="($curkind != $prevkind) or ($currootstep != $prevrootstep) or ($currootalter != $prevrootalter) or ($curduration + $prevduration &gt; $maxduration)">
			
				<if test="$debug">
					Measure:<value-of select="ancestor::measure/@number"/>
					Harmony position:<value-of select="position()"/>
					<!-- position() is always 1! not dependent on measure? or overall position in document? -->
					<!-- only dependent on context in which template is invoked (where position provided is always 1)? -->
					Last position:<value-of select="last()"/>
					<!-- and 'last()' is also always 1 here! -->
					Curr:<value-of select="concat($curkind,' ',$currootstep,' ',$currootalter,' ',$curduration)"/>
					Prev:<value-of select="concat($prevkind,' ',$prevrootstep,' ',$prevrootalter,' ',$prevduration)"/>
					Following:<value-of select="concat($nextkind,' ',$nextrootstep,' ',$nextrootalter,' ',$nextduration)"/> 
					Tot dur:<value-of select="$prevduration + $curduration"/>
				</if>
			
				<!-- start a new KeyVariation block in output -->
				<text>{"KeyVariation":</text>
				<value-of select="$keyvariation"/>
				<text>,"BlockType":0,</text>
				<text>"BeatCount":</text>
				<value-of select="$curduration div $divisions"/>
				<text>,</text>
				
				<!-- 'note' is a sibling of 'harmony', not a child element -->
				<!-- <apply-templates select="root/root-step"/> -->
				<text>"Key":</text>
				<!-- needs to be derived from both 'root-step' and 'root-alter' (accidental: 0=natural, 1=sharp, -1=flat) 
					(adding 12 before mod operation to account for 0-1, C-flat, i.e. B, and possible double-flats or sharps) -->
				<value-of select="$keyvalue"/>
				
				<text>,"BlockMixerState":</text>
				<text>[{"Level":0.5,"Mute":false,"Solo":false},</text>
				<text>{"Level":0.5,"Mute":false,"Solo":false},</text>
				<text>{"Level":0.5,"Mute":false,"Solo":false},</text>
				<text>{"Level":0.5,"Mute":false,"Solo":false},</text>
				<text>{"Level":0.5,"Mute":true,"Solo":false}]</text>
				
				<text>}</text>
				<!-- this test was for last harmony within a MEASURE -->
				<!-- will 'last()' give us the last harmony overall? -->
				<!-- 'position()' is always 1 in debug above -->
				<if test="position() != last()">
					<text>,</text>
				</if>
				<!-- ALL following harmonies, or just the first following curent node (and then it will cascade down the tree)-->
				<apply-templates select="following::harmony[1]">
					<with-param name="prevkind"><value-of select="$curkind"/></with-param> 
					<with-param name="prevduration"><value-of select="$curduration"/></with-param>
					<with-param name="prevrootstep"><value-of select="$currootstep"/></with-param>
					<with-param name="prevrootalter"><value-of select="$currootalter"/></with-param>
				</apply-templates>
				
			</when>
		</choose>
		
	</template>

</transform>