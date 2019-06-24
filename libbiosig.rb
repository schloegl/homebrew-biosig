class Libbiosig < Formula
  desc "Biosig library"
  homepage "https://biosig.sourceforge.io"
  url "https://downloads.sourceforge.net/project/biosig/BioSig%20for%20C_C%2B%2B/src/biosig4c%2B%2B-1.9.4.src.tar.gz"
  version "1.9.4"
  sha256 "f32339e14bf24faf37f2ddeaeeb1862a5b26aac6bb872a2c33b6684bca0ed02e"

  depends_on "gawk" => :build
  depends_on "gnu-sed" => :build
  depends_on "gnu-tar" => :build
  depends_on "pkg-config" => :build
  depends_on "dcmtk" => :build
  depends_on "suite-sparse" => :build

  patch :DATA

  def install
    system "./configure", "--disable-debug",
                          "--disable-dependency-tracking",
                          "--disable-silent-rules",
                          "--prefix=#{prefix}"

    system "make"
    system "make", "install_headers"
    system "make", "install_libbiosig"
  end

  test do
    # `test do` will create, run in and delete a temporary directory.
    #
    # This test will fail and we won't accept that! It's enough to just replace
    # "false" with the main program this formula installs, but it'd be nice if you
    # were more thorough. Run the test with `brew test biosig4c%2B%2B`. Options passed
    # to `brew install` such as `--HEAD` also need to be provided to `brew test`.
    #
    # The installed folder is not in the path, so use the entire path to any
    # executables being tested: `system "#{bin}/program", "do", "something"`.
    system "ls", "/usr/local/lib/libbiosig.dylib"
  end
end

__END__
diff --git a/Makefile.in b/Makefile.in
index 9e43e5ed..f3feca9d 100644
--- a/Makefile.in
+++ b/Makefile.in
@@ -137,6 +137,7 @@ else
 		OBJECTS += getlogin.o getline.o getdelim.o
 		LDLIBS  += -lssp
 		LDLIBS  += -liconv -lstdc++ -lws2_32
+		PKG_CONFIG_LIBS += -liconv -lws2_32
 		BINEXT   = .exe
 	endif
 endif
@@ -760,14 +761,13 @@ libbiosig.pc :
 	#
 	echo "Requires: "                   >> "$@"
 	echo "Requires.private: "           >> "$@"
-	echo "Cflags: $(DEFINES) -I$(includedir)"  >> "$@"
-	echo "Libs: -L$(libdir) -lbiosig"      >> "$@"
+	echo "Cflags: $(DEFINES) "          >> "$@"
+	echo "Libs: -lbiosig $(PKG_CONFIG_LIBS)" >> "$@"
 	echo "Libs.private: $(LDLIBS)"      >> "$@"
 
-
 ## save2gdf, pdp2gdf
 %${BINEXT}: %.c libbiosig.a
-	$(CC) $(DEFINES) $(CFLAGS) "$<" libbiosig.a -lstdc++ $(LDLIBS) -o "$@"
+	$(CC) $(DEFINES) $(CFLAGS) "$<" -L. -lbiosig -lstdc++ $(LDLIBS) -o "$@"
 
 physicalunits${BINEXT} : pu.c physicalunits.o
 	$(CC) $(DEFINES) $(CFLAGS) $^ $(LDFLAGS) $(LDLIBS) -o "$@"
@@ -817,7 +817,7 @@ mex/mexSOPEN.cpp : mex/mexSLOAD.cpp
 	echo "#define mexSOPEN" > mex/mexSOPEN.cpp
 	cat mex/mexSLOAD.cpp >> mex/mexSOPEN.cpp
 
-MEX_OBJECTS = mex/mexSLOAD.cpp mex/mexSOPEN.cpp mex/mexSSAVE.cpp
+MEX_OBJECTS = mex/mexSLOAD.cpp mex/mexSOPEN.cpp mex/mexSSAVE.cpp mex/physicalunits.cpp
 
 mex4o: $(patsubst mex/%.cpp, mex/%.mex, $(MEX_OBJECTS)) $(OBJECTS)
 oct: $(patsubst mex/%.cpp, mex/%.oct, $(MEX_OBJECTS)) $(OBJECTS)
diff --git a/biosig.c b/biosig.c
index 52dc1eba..1cc84c1d 100644
--- a/biosig.c
+++ b/biosig.c
@@ -968,14 +968,14 @@ void FreeTextEvent(HDRTYPE* hdr,size_t N_EVENT, const char* annotation) {
 	}
 
 	// Third, add event description if needed
-	if (flag) {
+	if (flag && (hdr->EVENT.LenCodeDesc < 256)) {
 		hdr->EVENT.TYP[N_EVENT] = hdr->EVENT.LenCodeDesc;
 		hdr->EVENT.CodeDesc[hdr->EVENT.LenCodeDesc] = annotation;
 		hdr->EVENT.LenCodeDesc++;
 	}
 
 	if (hdr->EVENT.LenCodeDesc > 255) {
-		biosigERROR(hdr, B4C_INSUFFICIENT_MEMORY, "Maximum number of user-defined events (256) exceeded");
+		biosigERROR(hdr, B4C_FORMAT_UNSUPPORTED, "Maximum number of user-defined events (256) exceeded");
 	}
 }
 
@@ -4694,6 +4694,7 @@ fprintf(stdout,"ACQ EVENT: %i POS: %i\n",k,POS);
 			CHANNEL_TYPE *hc = hdr->CHANNEL+k;
 			snprintf(hc->Label, MAX_LENGTH_LABEL+1, "%s %03i",label, chno2);
 
+			hc->Transducer[0] = 0;
 			hc->LeadIdCode = 0;
 			hc->SPR    = 1;
 			hc->Cal    = f1*f2;
@@ -5026,6 +5027,7 @@ fprintf(stdout,"ACQ EVENT: %i POS: %i\n",k,POS);
 					++hdr->NS;
 					hdr->CHANNEL = (CHANNEL_TYPE*)realloc(hdr->CHANNEL, hdr->NS*sizeof(CHANNEL_TYPE));
 					cp = hdr->CHANNEL+hdr->NS-1;
+					cp->Transducer[0] = 0;
 					cp->bi = hdr->AS.bpb;
 					cp->PhysDimCode = 0;
 					cp->HighPass = NAN;
@@ -5294,6 +5296,7 @@ fprintf(stdout,"ACQ EVENT: %i POS: %i\n",k,POS);
 		hdr->CHANNEL = (CHANNEL_TYPE*) realloc(hdr->CHANNEL,hdr->NS*sizeof(CHANNEL_TYPE));
 		for (k=0; k<hdr->NS; k++) {
 			CHANNEL_TYPE *hc = hdr->CHANNEL+k;
+			hc->Transducer[0] = 0;
 			sprintf(hc->Label,"#%03i",(int)k+1);
 			hc->Cal    = gain;
 			hc->Off    = offset;
@@ -6458,6 +6461,7 @@ if (VERBOSE_LEVEL > 7) fprintf(stdout,"biosig/%s (line %d): #%d label <%s>\n", _
 			hc->OnOff   = 1;
 
 			hc->PhysDimCode = 0;
+			hc->Transducer[0] = 0;
 		    	hc->DigMax	= ldexp( 1.0,31);
 		    	hc->DigMin	= ldexp(-1.0,31);
 		    	hc->PhysMax	= hc->DigMax * hc->Cal + hc->Off;
@@ -7240,6 +7244,7 @@ if (VERBOSE_LEVEL > 7) fprintf(stdout,"biosig/%s (line %d): #%d label <%s>\n", _
 			hc->GDFTYP = gdftyp;
 			hc->PhysDimCode = 4275;  // "uV"
 			hc->LeadIdCode  = 0;
+			hc->Transducer[0] = 0;
 			sprintf(hc->Label,"# %03i",(int)k);
 			hc->Cal	= PhysMax/ldexp(1,Bits);
 			hc->Off	= 0;
@@ -7370,7 +7375,92 @@ if (VERBOSE_LEVEL > 7) fprintf(stdout,"biosig/%s (line %d): #%d label <%s>\n", _
 
 #ifdef WITH_EMBLA
 	else if (hdr->TYPE==EMBLA) {
-		ifseek(hdr,48,SEEK_SET);
+
+		while (!ifeof(hdr)) {
+			size_t bufsiz = max(2*count, PAGESIZE);
+			hdr->AS.Header = (uint8_t*)realloc(hdr->AS.Header, bufsiz+1);
+			count  += ifread(hdr->AS.Header+count, 1, bufsiz-count, hdr);
+		}
+		hdr->AS.Header[count]=0;
+		hdr->HeadLen = count;
+		ifclose(hdr);
+
+		count = 48;
+
+		int chan;
+		uint32_t cal;
+		float chan32;
+		uint16_t pdc=0;
+		while (count+8 < hdr->HeadLen) {
+			uint32_t tag = leu32p(hdr->AS.Header+count);
+			uint32_t len = leu32p(hdr->AS.Header+count+4);
+			count+=8;
+/*
+			uint32_t taglen[2];
+			uint32_t *tag = &taglen[0];
+			uint32_t *len = &taglen[1];
+			size_t c = ifread(taglen, 4, 2, hdr);
+			if (ifeof(hdr)) break;
+*/
+			if (VERBOSE_LEVEL > 7) {
+				int ssz = min(80,len);
+				char S[81];
+				strncpy(S, hdr->AS.Header+count, ssz); S[ssz]=0;
+				fprintf(stdout,"tag %8d [%d]: <%s>\n",tag,len, S);
+			}
+
+			switch (tag) {
+			case 32:
+				hdr->SPR = len/2;
+//				hdr->AS.rawdata = realloc(hdr->AS.rawdata,len);
+				break;
+			case 133:
+				chan = leu16p(hdr->AS.Header+count);
+				fprintf(stdout,"\tchan=%d\n",chan);
+				break;
+			case 134:	// Sampling Rate
+				hdr->SampleRate=leu32p(hdr->AS.Header+count)/1000.0;
+				fprintf(stdout,"\tFs=%g #134\n",hdr->SampleRate);
+				break;
+			case 135:	//
+				cal=leu32p(hdr->AS.Header+count)/1000.0;
+				hc->Cal = (cal==1 ? 1.0 : cal*1e-9);
+				break;
+			case 136:	// session count
+				fprintf(stdout,"\t%d (session count)\n",leu32p(hdr->AS.Header+count));
+				break;
+			case 137:	// Sampling Rate
+				hdr->SampleRate=lef64p(hdr->AS.Header+count);
+				fprintf(stdout,"\tFs=%g #137\n",hdr->SampleRate);
+				break;
+			case 141:
+				chan32 = lef32p(hdr->AS.Header+count);
+				fprintf(stdout,"\tchan32=%g\n",chan32);
+				break;
+			case 144:	// Label
+				strncpy(hc->Label, hdr->AS.Header+count, MAX_LENGTH_LABEL);
+				hc->Label[min(MAX_LENGTH_LABEL,len)]=0;
+				break;
+			case 153:	// Label
+				pdc=PhysDimCode(hdr->AS.Header+count);
+				fprintf(stdout,"\tpdc=0x%x\t<%s>\n",pdc,PhysDim3(pdc));
+				break;
+			case 208:	// Patient Name
+				if (!hdr->FLAG.ANONYMOUS)
+					strncpy(hdr->Patient.Name, hdr->AS.Header+count, MAX_LENGTH_NAME);
+					hdr->Patient.Name[min(MAX_LENGTH_NAME,len)]=0;
+				break;
+			case 209:	// Patient Name
+				strncpy(hdr->Patient.Id, hdr->AS.Header+count, MAX_LENGTH_PID);
+				hdr->Patient.Id[min(MAX_LENGTH_PID,len)]=0;
+				break;
+			default:
+				;
+			}
+			count+=len;
+		}
+
+
 		hdr->NS = 1;
 		hdr->CHANNEL = (CHANNEL_TYPE*)realloc(hdr->CHANNEL, hdr->NS * sizeof(CHANNEL_TYPE));
 		for (k=0; k < hdr->NS; k++) {
@@ -7392,7 +7482,7 @@ if (VERBOSE_LEVEL > 7) fprintf(stdout,"biosig/%s (line %d): #%d label <%s>\n", _
 			hc->bi   = k*hdr->SPR*2;
 
 			char *label = (char*)(hdr->AS.Header+1034+k*512);
-			len    = min(16,MAX_LENGTH_LABEL);
+			const size_t len    = min(16,MAX_LENGTH_LABEL);
 			if ( (hdr->AS.Header[1025+k*512]=='E') && strlen(label)<13) {
 				strcpy(hc->Label, "EEG ");
 				strcat(hc->Label, label);		// Flawfinder: ignore
@@ -7403,26 +7493,9 @@ if (VERBOSE_LEVEL > 7) fprintf(stdout,"biosig/%s (line %d): #%d label <%s>\n", _
 			}
 		}
 
-		while (1) {
-			uint32_t taglen[2];
-			uint32_t *tag = &taglen[0];
-			uint32_t *len = &taglen[1];
-			size_t c = ifread(taglen, 4, 2, hdr);
-			if (ifeof(hdr)) break;
-			switch (*tag) {
-			case 32:
-				hdr->HeadLen = iftell(hdr);
-				hdr->SPR = *len/2;
-				hdr->AS.rawdata = realloc(hdr->AS.rawdata,*len);
-				ifread(hdr->AS.rawdata,2,*len/2,hdr);
-
-			default:
-				ifseek(hdr,*len,SEEK_CUR);
-			}
-			//strncpy(hdr->CHANNEL[k].Label,buf+0x116,MAX_LENGTH_LABEL);
-		}
 	}
-#endif
+
+#endif // EMBLA
 	else if (hdr->TYPE==EMSA) {
 		
 		hdr->NS = (uint8_t)hdr->AS.Header[3];
@@ -8431,6 +8504,7 @@ if (VERBOSE_LEVEL>7) fprintf(stdout,"MFER: TLV %i %i %i \n",tag,len,(int)hdr->NS
 					hc->Cal = 1.0;
 					hc->LeadIdCode = 0; 
 					hc->GDFTYP = 3;
+					hc->Transducer[0] = 0;
 				}
 			}
 			else if (tag==6) 	// 0x06 "number of sequences"
@@ -8907,6 +8981,7 @@ if (VERBOSE_LEVEL>2)
 	 			fprintf(stdout,"sopen(MFER): #%i\n",(int)k);
 
 			CHANNEL_TYPE *hc = hdr->CHANNEL+k;
+			hc->Transducer[0] = 0;
 	 		if (!hc->PhysDimCode) hc->PhysDimCode = MFER_PhysDimCodeTable[UnitCode];
 	 		if (hc->Cal==1.0) hc->Cal = Cal;
 	 		hc->Off = Off * hc->Cal;
@@ -9394,6 +9469,7 @@ if (VERBOSE_LEVEL>2)
 
 						while (ns < ch) {
 							hdr->rerefCHANNEL[ns].Label[0] = 0;
+							hdr->rerefCHANNEL[ns].Transducer[0] = 0;
 							ns++;
 						}
 					}	 
@@ -9455,6 +9531,7 @@ if (VERBOSE_LEVEL>2)
 		hdr->CHANNEL[0].LowPass  = NAN;
 		hdr->CHANNEL[0].HighPass = NAN;
 		hdr->CHANNEL[0].Notch    = NAN;
+		hdr->CHANNEL[0].Transducer[0] = 0;
 
 	if (VERBOSE_LEVEL>7) fprintf(stdout,"NEURON 202: \n");
 
@@ -9638,6 +9715,7 @@ if (VERBOSE_LEVEL>2)
 				//neuralEventWaveform = identifier + 8;
 				CHANNEL_TYPE *hc = hdr->CHANNEL+(NS++);
 				sprintf(hc->Label,"#%d",leu16p(identifier + 8));	// electrodeId
+				hc->Transducer[0] = 0;
 				// (uint8_t)(identifier + 8 + 2);	// module
 				// (uint8_t)(identifier + 8 + 3);	// channel
 				hc->OnOff = 1;
@@ -9661,7 +9739,6 @@ if (VERBOSE_LEVEL>2)
 				hc->XYZ[1] = 0;
 				hc->XYZ[2] = 0;
 				hc->Impedance = NAN;
-
 				
 				hc->SPR = 0;
 				hc->bi = hdr->AS.bpb;
@@ -9746,6 +9823,7 @@ if (VERBOSE_LEVEL>2)
 
 			strncpy(hc->Label, hdr->AS.Header + H1LEN + k*H2LEN + 8, min(64,MAX_LENGTH_LABEL));
 			hc->Label[min(64, MAX_LENGTH_LABEL)] = 0;
+			hc->Transducer[0] = 0;
 
 			size_t n;
 			if (v==5) {
@@ -9970,6 +10048,8 @@ if (VERBOSE_LEVEL>2)
 		typeof (hdr->NS) k;
 		for (k=0; k<hdr->NS; k++) {
 			CHANNEL_TYPE *hc = hdr->CHANNEL+k;
+			hc->Transducer[0] = 0;
+			hc->Label[0] = 0;
 			hc->GDFTYP = gdftyp;
 			hc->SPR    = hdr->SPR;
 			hc->Cal    = 1.0;
@@ -10382,6 +10462,7 @@ if (VERBOSE_LEVEL>2)
 			CHANNEL_TYPE *hc = hdr->CHANNEL + k;
 			hc->OnOff = 1;
 			strncpy(hc->Label,(char*)(hdr->AS.Header+32+24+8*k),8);
+			hc->Transducer[0] = 0;
 			hc->LeadIdCode = 0; 
 		}
     		biosigERROR(hdr, B4C_FORMAT_UNSUPPORTED, "Format RDF (UCSD ERPSS) not supported");
@@ -10527,7 +10608,9 @@ if (VERBOSE_LEVEL>2)
 	      		hc->XYZ[0]    = 0.0;
 		      	hc->XYZ[1]    = 0.0;
 		      	hc->XYZ[2]    = 0.0;
-			hc->LeadIdCode = 0; 
+			hc->LeadIdCode = 0;
+			hc->Transducer[0] = 0;
+			hc->Label[0] = 0;
 
 			unsigned k1;
 			for (k1 = sizeof(p)/sizeof(p[0]); k1>0; ) {
@@ -11234,6 +11317,7 @@ if (VERBOSE_LEVEL>2)
 		size_t bpb8=0;
 		for (k = 0; k < hdr->NS; k++) {
 			CHANNEL_TYPE *hc = hdr->CHANNEL+k;
+			hc->Transducer[0] = 0;
 			hc->GDFTYP  =  gdftyp;
 			hc->OnOff   =  1;
 			hc->bi      =  bpb8>>3;
diff --git a/configure.ac b/configure.ac
index 9ef0989b..ccfbdd5c 100644
--- a/configure.ac
+++ b/configure.ac
@@ -41,7 +41,7 @@ AC_CHECK_LIB([z],       [gzopen],              AC_SUBST(HAVE_LIBZ,       "1") )
 
 AC_CHECK_LIB([iconv], [iconv_open])
 AC_CHECK_HEADER([iconv.h], ,[AC_MSG_ERROR([can not find iconv.h])])
-#AC_CHECK_LIB([tinyxml] , [main],        AC_SUBST(HAVE_LIBTINYXML, "1")  [TEST_LIBS="$TEST_LIBS -ltinyxml"],   AC_MSG_WARN([libtinyxml is not installed.]))
+AC_CHECK_LIB([tinyxml] , [main],        AC_SUBST(HAVE_LIBTINYXML, "1")  [TEST_LIBS="$TEST_LIBS -ltinyxml"],   AC_MSG_WARN([libtinyxml is not installed.]))
 #AC_CHECK_LIB([tinyxml2], [main],        AC_SUBST(HAVE_LIBTINYXML2, "1") [TEST_LIBS="$TEST_LIBS -ltinyxml2"],  AC_MSG_WARN([libtinyxml2 is not installed.]))
 
 AC_CHECK_PROG(HAVE_OCTAVE,[mkoctfile],"1")
diff --git a/t210/sopen_abf_read.c b/t210/sopen_abf_read.c
index fdbf2e49..10169239 100644
--- a/t210/sopen_abf_read.c
+++ b/t210/sopen_abf_read.c
@@ -745,6 +745,7 @@ EXTERN_C void sopen_abf2_read(HDRTYPE* hdr) {
 			hc->bufptr = NULL;
 			hc->LeadIdCode = 0;
 			hc->OnOff = 1;
+			hc->Transducer[0] = 0;
 
 			hc->LowPass  = lef32p(hdr->AS.auxBUF + S.uBytes*k + offsetof(struct ABF_ADCInfo, fSignalLowpassFilter));
 			hc->HighPass = lef32p(hdr->AS.auxBUF + S.uBytes*k + offsetof(struct ABF_ADCInfo, fSignalHighpassFilter));
diff --git a/t210/sopen_alpha_read.c b/t210/sopen_alpha_read.c
index 3e95e25d..ed382d79 100644
--- a/t210/sopen_alpha_read.c
+++ b/t210/sopen_alpha_read.c
@@ -158,6 +158,7 @@ if (VERBOSE_LEVEL>7) fprintf(stdout,"<%6.2f> %i- %s | %s\n",hdr->VERSION, STATUS
 						hc->Off     = 0.0; 
 						hc->PhysMax = hc->DigMax; 
 						hc->PhysMin = hc->DigMin; 
+						hc->Transducer[0] = 0;
 					
 						strncpy(hc->Label, t, MAX_LENGTH_LABEL+1);
 						char* t2= strchr(t1,',');
diff --git a/t210/sopen_cfs_read.c b/t210/sopen_cfs_read.c
index a5cc6cb7..bf67e870 100644
--- a/t210/sopen_cfs_read.c
+++ b/t210/sopen_cfs_read.c
@@ -201,6 +201,7 @@ if (VERBOSE_LEVEL>7) fprintf(stdout,"%s(line %i) Channel #%i/%i: %i<%s>/%i<%s>\n
 			}
 			hc->bi = bpb;
 			bpb += GDFTYP_BITS[hc->GDFTYP]>>3;	// per single sample
+			hc->Transducer[0] = '\0';
 			hc->Impedance = NAN;
 			hc->TOffset  = NAN;
 			hc->LowPass  = NAN;
@@ -1022,6 +1023,7 @@ EXTERN_C void sopen_smr_read(HDRTYPE* hdr) {
 		hc->SPR   = 0;
 		hc->GDFTYP = 3;
 		hc->LeadIdCode = 0;
+		hc->Transducer[0] = '\0';
 
 		int stringLength = hdr->AS.Header[off+108];
 		assert(stringLength < MAX_LENGTH_LABEL);
diff --git a/t230/sopen_hl7aecg.cpp b/t230/sopen_hl7aecg.cpp
index b72e0611..c8ea9093 100644
--- a/t230/sopen_hl7aecg.cpp
+++ b/t230/sopen_hl7aecg.cpp
@@ -265,6 +265,7 @@ EXTERN_C int sopen_HL7aECG_read(HDRTYPE* hdr) {
 			CHANNEL_TYPE *hc = hdr->CHANNEL+k;
 			hc->GDFTYP   = 16;
 			sprintf(hc->Label,"#%i",k);
+			hc->Transducer[0] = 0;
 			hc->Cal      = Cal;
 			hc->Off      = 0.0;
 			hc->OnOff    = 1;
@@ -395,6 +396,7 @@ EXTERN_C int sopen_HL7aECG_read(HDRTYPE* hdr) {
 				hc->DigMin 	= (double)(int16_t)0x8000;			
 				hc->DigMax	= (double)(int16_t)0x7fff;	
 				strncpy(hc->Label, C->Attribute("lead"), MAX_LENGTH_LABEL);
+				hc->Transducer[0] = 0;
 
 				hc->LeadIdCode	= 0;
 				size_t j;
