<?xml version="1.0" encoding="UTF-8" ?>
<transform version="1.0" xmlns="http://www.w3.org/1999/XSL/Transform">
<output method="text" encoding="utf-8"/>

<!-- Author: Kent Finley -->
<!-- Purpose: Convert MusicXML file as exported by iReal Pro to JSON format required by SessionBand Jazz Volume 1 -->
<!-- Internet Explorer can act as an XSLT processor - insert reference to this stylesheet (transform) into extracted MusicXML file -->
<!-- e.g. 
     <?xml-stylesheet type="text/xsl" href="file://C:\Users\username\Desktop\musicxml2sessionbandjazz.xsl"?>
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
		<apply-templates select="part/measure"/>
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

    <template match="root/root-step">
		<variable name="root-alter" select="following-sibling::root-alter" />
		<text>"Key":</text>
		<!-- needs to be derived from both 'root-step' and 'root-alter' (accidental: 0=natural, 1=sharp, -1=flat) 
			(adding 12 before mod operation to account for 0-1, C-flat, i.e. B, and possible double-flats or sharps) 
			SessionBand Jazz (all volumes) C=0,Db=1,D=2,Eb=3,...B=11 -->
		<choose>
		   <when test=".='C'"><value-of select="(0+$root-alter+12) mod 12"/></when>
		   <when test=".='D'"><value-of select="(2+$root-alter+12) mod 12"/></when>
		   <when test=".='E'"><value-of select="(4+$root-alter+12) mod 12"/></when>
		   <when test=".='F'"><value-of select="(5+$root-alter+12) mod 12"/></when>
		   <when test=".='G'"><value-of select="(7+$root-alter+12) mod 12"/></when>
		   <when test=".='A'"><value-of select="(9+$root-alter+12) mod 12"/></when>
		   <when test=".='B'"><value-of select="(11+$root-alter+12) mod 12"/></when>
		   <otherwise><apply-templates/></otherwise>
		</choose>
		<text>,"BlockMixerState":</text>
		<text>[{"Level":0.5,"Mute":false,"Solo":false},</text>
		<text>{"Level":0.5,"Mute":false,"Solo":false},</text>
		<text>{"Level":0.5,"Mute":false,"Solo":false},</text>
		<text>{"Level":0.5,"Mute":false,"Solo":false},</text>
		<text>{"Level":0.5,"Mute":true,"Solo":false}]</text>

    </template>

    <template match="note/duration">
		<text>"BeatCount":</text>
		<!-- needs to be derived from 'divisions' and 'duration' -->
		<value-of select=". div $divisions"/>
		<text>,</text>
    </template>

    <template match="kind">
		<variable name="halfdim" select="../degree[degree-value='5' and degree-alter='-1' and (degree-type='add' or degree-type='alter')]"/>
		<!-- this will actually be the 'result tree fragment' of the degree or degrees that match the predicate -->
		
		<text>{"KeyVariation":</text>
		<choose>
			<when test=".='major-minor'">8</when> 
			<when test="starts-with(.,'major')">0</when>    
			<when test="starts-with(.,'minor')">
				<choose>
					<when test="$halfdim">7</when>
					<otherwise>6</otherwise>
				</choose>
			</when>    
			<when test="starts-with(.,'dominant')">2</when>    
			<!--but there can be many alterations of the dominant, depending on 'degree'-->
			<when test=".='augmented'">4</when>    
			<!-- not really quite right, mapping to dom7#5#9-->
			<when test="starts-with(.,'diminished')">9</when>    
			<!-- but diminished could also be entered as m(7)b5 in iReal Pro -->
			<when test=".='half-diminished'">7</when>    
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
		<text>,"BlockType":0,</text>
    </template>

    <template match="part/measure">
		<for-each select="harmony">
			<apply-templates select="kind"/>
			<apply-templates select="following-sibling::note[1]/duration"/>	
			<apply-templates select="root/root-step"/>
			<text>}</text>
			<if test="position() != last()">
				<text>,</text>
			</if>
		</for-each>
		<if test="position() != last()">
			<text>,</text>
		</if>
	</template>

</transform>