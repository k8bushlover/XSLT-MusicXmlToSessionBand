<?xml version="1.0" encoding="UTF-8" ?>
<transform version="1.0" xmlns="http://www.w3.org/1999/XSL/Transform">
<output method="text" encoding="utf-8"/>

<!-- Author: Kent Finley -->
<!-- Purpose: Convert MusicXML file as exported by iReal Pro to JSON format required by SessionBand Jazz Volume 1 -->
<!-- Internet Explorer can act as an XSLT processor - insert reference to this stylesheet (transform) into extracted MusicXML file -->
<!-- e.g. 
     <?xml-stylesheet type="text/xsl" href="C:\Users\username\Desktop\musicxml-to-sbj.xsl"?>	 
	    can omit the path and just give the filename, if files in same directory
		type="text/xml" is actually technically correct, but IE may or may not process it that way
-->	
<!-- then drag the .xml file to the current address bar in IE, save resulting text (and text ONLY) in a file with ".sbj" as extension -->
<!-- import .sbj file into SessionBand Jazz Volume 1 via iTunes -->

<!-- NOT suitable for converting files with multiple time signatures, files with more than one note per harmony -->
<!-- only chord charts as exported by iReal Pro as MusicXML files, basically -->
<!-- not extracting key signature from MusicXML file, as it doesn't really matter in SessionBand Jazz Volume 1 -->

<!-- assuming there will only be one 'part' to the score, and that measure number 1 will hold the time signature and divisions -->
<!-- exceptions to the above will probably NOT process correctly -->

	<variable name="divisions" select="score-partwise/part[1]/measure[1]/attributes/divisions" />
	<variable name="beats" select="score-partwise/part[1]/measure[1]/attributes/time/beats" />
	<!--  'beat-type' value (time signature denominator) won't be used in this version
		but may be helpful in distinguishing between 4 feel and 2 feel signatures in the future -->
	<!--
	<variable name="beat-type" select="score-partwise/part[1]/measure[1]/attributes/time/beat-type" />
	-->
	<variable name="maxduration" select="$beats * $divisions * 2" />
	
    <template match="score-partwise">
		<text>{</text>
		<text>"TrackName":"</text><value-of select="./movement-title"/><text>"</text>
		<text>,"TrackItems":[</text>
		<apply-templates select="part[1]/measure[1]/harmony[1]"/>
		<!-- here, we want only the first occurrence of harmony in the document overall -->
		<!-- the remainder will be processed from within that template, sequentially, each checking the next for certain conditions -->
		<text>]</text>
		<text>,"PlaybackSpeed":1</text>
		<text>,"TrackAuthor":"</text>
		<value-of select="identification/creator[@type='composer']"/>
		<!-- <text>","TrackComments":[]</text> -->
		<!-- any text on individual bars in form of {"BarIndex":bar# (from 0),"CommentKey":"text"(up to 10 chars)} -->
		<!-- look for <direction> instructions in MusicXML -->
		<!-- some will be <direction-type><words>text</words></direction-type>, some will be <coda/>,<segno/>, maybe <dalsegno/> -->
		<!-- straightforward enough if not taking repeats into account, since measure number in MusicXML will correspond to bar# + 1 in SBJ -->
		<call-template name="comments"/>
		<text>,"TrackMixer":</text>
		<text>[{"Level":0.5,"Mute":false,"Solo":false},</text>
		<text>{"Level":0.5,"Mute":false,"Solo":false},</text>
		<text>{"Level":0.5,"Mute":false,"Solo":false},</text>
		<text>{"Level":0.5,"Mute":false,"Solo":false},</text>
		<text>{"Level":0.5,"Mute":true,"Solo":false}]</text>
		<text>,"Genre":</text>
		<choose>
			<when test="($beats mod 3 = 0) and ($beats mod 2 != 0)">"Medium 3/4"</when>
			<when test="($beats mod 2 = 0)">"Medium Swing (4 feel)"</when>
			<otherwise>"Bossa Nova"</otherwise>
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
		<text>}</text>
	</template>

	<template name="comments">
		<text>","TrackComments":[</text>
		<!-- loop through measures with <direction> elements-->
		<for-each select="part[1]/measure[direction]"> 
			<text>{"BarIndex":</text>
			<value-of select="position()-1"/>
			<text>,"CommentKey":</text>
			<!-- take just the 1st direction, if more than one, since comments can only be up to 10 characters -->
			<for-each select="direction[1]/direction-type/*">
				<choose>
					<when test="name()='words' or name()='rehearsal'">
						<value-of select="substring(.,1,10)"/>
					</when>
					<when test="self::*">
						<value-of select="substring(name(),1,10)"/>
					</when>
				</choose>
			</for-each>
			<text>}</text>
			<if test="position()!=last()">
				<text>,</text>
			</if>
		</for-each>
		<text>]</text>
	</template>
	
	<template match="harmony">
	
		<!-- need to delay processing until we know that following measure is not the same harmony with a duration that would
		     fit within 2 measures (considering total duration accumulated so far), OR that there is no following measure-->
		
		<param name="accumduration">0</param>
				 
		<variable name="curkind" select="kind"/>
		<variable name="curduration" select="following-sibling::note[1]/duration"/>
		<variable name="currootstep" select="root/root-step"/>
		<variable name="currootalter" select="root/root-alter"/>
		
		<variable name="nextkind" select="following::harmony[1]/kind"/>
		<variable name="nextduration" select="following::harmony[1]/following-sibling::note[1]/duration"/>
		<variable name="nextrootstep" select="following::harmony[1]/root/root-step"/>
		<variable name="nextrootalter" select="following::harmony[1]/root/root-alter"/>
		
		<!-- these will actually be the 'result tree fragments' of the degree or degrees that match the predicates -->
		<!-- the fact of their having a value will be enough to treat them as a 'boolean' variable, in version 1.0 -->
		<!-- 2.0 processors may change that(?) so an explicit cast to boolean might be better -->
		<variable name="subthree" select="degree[degree-value='3' and degree-type='subtract']"/>
		<variable name="addfour" select="degree[degree-value='4' and degree-alter='0' and degree-type='add']"/>
		<variable name="sharpfour" select="degree[degree-value='4' and degree-alter='1' and (degree-type='add' or degree-type='alter')] |
		degree[degree-value='11' and degree-alter='1' and (degree-type='add' or degree-type='alter')]"/>
		<variable name="flatfive" select="degree[degree-value='5' and degree-alter='-1' and (degree-type='add' or degree-type='alter')]"/>
		<variable name="sharpfive" select="degree[degree-value='5' and degree-alter='1' and (degree-type='add' or degree-type='alter')] |
		degree[degree-value='13' and degree-alter='-1' and (degree-type='add' or degree-type='alter')]"/>
		<variable name="addseven" select="degree[degree-value='7' and degree-alter='0' and degree-type='add']"/>
		<variable name="flatnine" select="degree[degree-value='9' and degree-alter='-1' and (degree-type='add' or degree-type='alter')]"/>
		<variable name="sharpnine" select="degree[degree-value='9' and degree-alter='1' and (degree-type='add' or degree-type='alter')]"/>
					
		<variable name="keyvariation">
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
			<choose>
				<when test="starts-with($curkind,'diminished')">9</when>    
				<when test="$curkind='major-minor'">8</when> 
				<!-- important to test above first, or condition 'starts-with(.,"major")'would pass -->
				<when test="$curkind='half-diminished'">7</when>    
				<when test="starts-with($curkind,'minor')">
					<choose>
						<when test="$flatfive">7</when>
						<otherwise>6</otherwise>
					</choose>
				</when>
				<when test="starts-with($curkind,'dominant')">
					<choose>
						<when test="$addfour and $subthree">5</when>
						<when test="$sharpfive or $sharpnine">4</when>
						<when test="$flatnine">3</when>
						<otherwise>2</otherwise>
					</choose>
				</when>    
				<when test="$curkind='suspended-fourth' and $addseven">5</when>
				<when test="$curkind='augmented'">4</when>    
				<!-- not really quite right, mapping to dom7#5#9, -->
				<when test="starts-with($curkind,'major')">
					<choose>
						<when test="$sharpfour">1</when>
						<otherwise>0</otherwise>
					</choose>
				</when>    
				<otherwise>0</otherwise>
			</choose>
		</variable>
		
		<variable name="keyvalue">
		<!-- needs to be derived from both 'root-step' and 'root-alter' (accidental: 0=natural, 1=sharp, -1=flat) 
					(adding 12 before mod operation to account for 0-1, C-flat, i.e. B, and possible double-flats or sharps) -->
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
			<when test="not(following::harmony) or ($curkind != $nextkind) or ($currootstep != $nextrootstep) or ($currootalter != $nextrootalter) or ($accumduration + $curduration &gt;= $maxduration) or ($accumduration + $curduration + $nextduration &gt; $maxduration)">
			<!-- may not account for EVERY possible combination, esp. in changing time signatures (which will process oddly anyway) -->
			
			<!-- start a new KeyVariation block in output -->
				<text>{"KeyVariation":</text>
				<value-of select="$keyvariation"/>
				<text>,"BlockType":0</text>
				<text>,"BeatCount":</text>
				<choose>
					<when test="$accumduration + $curduration &gt; $maxduration">
						<value-of select="$maxduration div $divisions"/>
					</when>
					<otherwise>
						<value-of select="($accumduration + $curduration) div $divisions"/>
					</otherwise>
				</choose>
				<text>,"Key":</text>
				<value-of select="$keyvalue"/>
				<text>,"BlockMixerState":</text>
				<text>[{"Level":0.5,"Mute":false,"Solo":false},</text>
				<text>{"Level":0.5,"Mute":false,"Solo":false},</text>
				<text>{"Level":0.5,"Mute":false,"Solo":false},</text>
				<text>{"Level":0.5,"Mute":false,"Solo":false},</text>
				<text>{"Level":0.5,"Mute":true,"Solo":false}]}</text>
				<if test="following::harmony">
					<text>,</text>
				</if>
				<apply-templates select="following::harmony[1]">
					<with-param name="accumduration">0</with-param>
				</apply-templates>
			</when>
			<otherwise>
				<apply-templates select="following::harmony[1]">
					 <with-param name="accumduration" select="$accumduration + $curduration"/>
				</apply-templates>
			</otherwise>
		</choose>
		
	</template>

</transform>