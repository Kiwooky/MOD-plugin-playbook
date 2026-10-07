# TEST RECIPE (MOD plugin playbook): does the Online Builder allow downloads
# during a build? The plugin is the template echo; its pedal face (MOD SDK
# "japanese", white, black knobs) is NOT embedded: the install step downloads
# the SDK template, CSS and art from GitHub with wget.
# Build fails with "face: could not download ..." = no network on the builder.
# Build succeeds = check the face on the pedalboard.
#
# Upload this file at https://builder.mod.audio/buildroot with a MOD unit
# connected over USB. Assembled by tools/assemble_recipe.py (MOD plugin playbook).


FACE_FETCH_TEST_VERSION = 61d38eb638449647fb8395a35c5b8dab7e981ba7
FACE_FETCH_TEST_SITE = https://github.com/DISTRHO/DPF.git
FACE_FETCH_TEST_SITE_METHOD = git
FACE_FETCH_TEST_BUNDLES = face-fetch-test.lv2

define FACE_FETCH_TEST_SRC1
#ifndef DISTRHO_PLUGIN_INFO_H_INCLUDED
#define DISTRHO_PLUGIN_INFO_H_INCLUDED

// Rename these together with the TTL (see docs/lv2-and-mod-rules.md).
#define DISTRHO_PLUGIN_BRAND       "MOD Cookbook"
#define DISTRHO_PLUGIN_NAME        "Face Fetch Test"
#define DISTRHO_PLUGIN_URI         "urn:mod-cookbook:face-fetch-test"

#define DISTRHO_PLUGIN_HAS_UI       0
#define DISTRHO_PLUGIN_IS_RT_SAFE   1
#define DISTRHO_PLUGIN_NUM_INPUTS   1
#define DISTRHO_PLUGIN_NUM_OUTPUTS  1

// Control ports, in TTL order (indices start after the audio ports).
// The bypass port is always last.
enum Parameters {
    kTime = 0,
    kFeedback,
    kMix,
    kTails,
    kBypass,
    kParameterCount
};

#endif
endef

define FACE_FETCH_TEST_SRC2
#!/usr/bin/make -f
# DSP-only LV2 build. NAME = the bundle name; the binary is <NAME>_dsp.so.
NAME = face-fetch-test
FILES_DSP = SimpleEchoPlugin.cpp
include ../../Makefile.plugins.mk
TARGETS = lv2_dsp
all: $$(TARGETS)
endef

define FACE_FETCH_TEST_SRC3
// Simple Echo: the playbook's template plugin. It's an echo, so it carries most
// traits (docs/effect-profile.md). Each part is tagged with the trait it serves:
//   [every]    every plugin: real-time run(), first-run snap, smoothing,
//              in-plugin bypass with a ~10 ms crossfade (lv2:enabled port, last)
//   [buffer]   stores audio: allocated up front, sized for 96 kHz
//   [tail]     sound continues after the input stops: the Tails option
//   [feedback] output fed back in: denormal guard, saturator in the loop,
//              soft limit on the WET path so a runaway can't hit the converter
//   [mix]      has a Mix knob: dry back to unity in bypass whatever Mix says
// Delete the parts for traits your plugin doesn't have, with their ports and tests.
// A gain or drive pedal gets no output limiter: its clipping is the sound.
#include "DistrhoPlugin.hpp"

#include <cmath>
#include <cstring>
#include <cstdint>

START_NAMESPACE_DISTRHO

static const uint32_t kBufSize = 1u << 18;      // [buffer] 2.7 s at 96 kHz
static const uint32_t kBufMask = kBufSize - 1;

static inline float clampf(float x, float lo, float hi) { return x < lo ? lo : (x > hi ? hi : x); }
static inline float onePoleCoef(float hz, float sr) { return 1.0f - std::exp(-6.2831853f * hz / sr); }

// [feedback] rational tanh: smooth, flat beyond |x| = 3, no libm call per sample
static inline float softClip(float x)
{
    if (x >  3.0f) return  1.0f;
    if (x < -3.0f) return -1.0f;
    const float x2 = x * x;
    return x * (27.0f + x2) / (27.0f + 9.0f * x2);
}

// [feedback] linear below k, approaches k + r smoothly, never above it
static inline float softKnee(float x, float k, float r)
{
    const float a = std::fabs(x);
    if (a <= k) return x;
    const float y = k + r * softClip((a - k) / r);
    return x < 0.0f ? -y : y;
}

class SimpleEchoPlugin : public Plugin
{
public:
    SimpleEchoPlugin()
        : Plugin(kParameterCount, 0, 0)
    {
        fParams[kTime] = 350.0f;
        fParams[kFeedback] = 40.0f;
        fParams[kMix] = 35.0f;
        fParams[kTails] = 1.0f;
        fParams[kBypass] = 0.0f;
        std::memset(fBuf, 0, sizeof(fBuf));
    }

protected:
    const char* getLabel()       const override { return "SimpleEcho"; }
    const char* getDescription() const override { return "Playbook test: a stock face downloaded at build time."; }
    const char* getMaker()       const override { return DISTRHO_PLUGIN_BRAND; }
    const char* getLicense()     const override { return "GPL-3.0-or-later"; }
    uint32_t    getVersion()     const override { return d_version(1, 0, 0); }   // = lv2:minorVersion 2, microVersion 0
    int64_t     getUniqueId()    const override { return d_cconst('f', 'F', 't', '1'); }

    void initParameter(uint32_t index, Parameter& p) override
    {
        p.hints = kParameterIsAutomatable;
        switch (index) {
        case kTime:
            p.hints |= kParameterIsLogarithmic;
            p.name = "Time"; p.symbol = "time"; p.unit = "ms";
            p.ranges.min = 20.0f; p.ranges.max = 2000.0f; p.ranges.def = 350.0f;
            break;
        case kFeedback:
            p.name = "Feedback"; p.symbol = "feedback"; p.unit = "%";
            p.ranges.min = 0.0f; p.ranges.max = 95.0f; p.ranges.def = 40.0f;
            break;
        case kMix:
            p.name = "Mix"; p.symbol = "mix"; p.unit = "%";
            p.ranges.min = 0.0f; p.ranges.max = 100.0f; p.ranges.def = 35.0f;
            break;
        case kTails:                                          // [tail]
            p.hints |= kParameterIsInteger | kParameterIsBoolean;
            p.name = "Tails"; p.symbol = "tails";
            p.ranges.min = 0.0f; p.ranges.max = 1.0f; p.ranges.def = 1.0f;
            break;
        case kBypass:                                         // [every]
            p.initDesignation(kParameterDesignationBypass);   // TTL: lv2_enabled, lv2:designation lv2:enabled
            break;
        }
    }

    float getParameterValue(uint32_t i) const override { return i < kParameterCount ? fParams[i] : 0.0f; }
    void  setParameterValue(uint32_t i, float v) override { if (i < kParameterCount) fParams[i] = v; }

    void activate() override
    {
        fSr = (float)getSampleRate();
        fSmooth = onePoleCoef(1.0f / (6.2831853f * 0.010f), fSr);    // 10 ms
        fTimeSm = onePoleCoef(1.0f / (6.2831853f * 0.100f), fSr);    // 100 ms glide on Time
        std::memset(fBuf, 0, sizeof(fBuf));
        fW = 0; fFbState = 0.0f;
        fFirst = true;
    }

    void run(const float** inputs, float** outputs, uint32_t frames) override
    {
        const float* in = inputs[0];
        float* out = outputs[0];

        const float dTarget  = clampf(fParams[kTime] * 0.001f * fSr, 4.0f, (float)kBufSize - 4.0f);
        const float fbTarget = clampf(fParams[kFeedback] * 0.01f, 0.0f, 0.95f);
        const float mix      = clampf(fParams[kMix] * 0.01f, 0.0f, 1.0f);
        const bool  bypass   = fParams[kBypass] > 0.5f;
        const bool  tails    = fParams[kTails] > 0.5f;
        // [every] bypass fades over ~10 ms instead of switching hard (mod-host's own bypass
        // jumps straight to dry on the next block, which clicks on a processed signal)
        const float inT      = bypass ? 0.0f : 1.0f;              // [tail] mute only the input...
        const float wetT     = (bypass && !tails) ? 0.0f : mix;   // [tail] ...so the tail rings out
        const float dryT     = bypass ? 1.0f : 1.0f - mix;        // [mix] dry to unity in bypass

        if (fFirst) {                    // [every] controls arrive with the first run()
            fFirst = false;
            fD = dTarget; fFb = fbTarget; fIn = inT; fWet = wetT; fDry = dryT;
        }

        for (uint32_t i = 0; i < frames; ++i) {
            fD   += fTimeSm * (dTarget - fD);
            fFb  += fSmooth * (fbTarget - fFb);
            fIn  += fSmooth * (inT - fIn);
            fWet += fSmooth * (wetT - fWet);
            fDry += fSmooth * (dryT - fDry);

            // linear-interpolated read, fD samples back
            const uint32_t ip = (uint32_t)fD;
            const float t = fD - (float)ip;
            const float a = fBuf[(fW - ip) & kBufMask];
            const float b = fBuf[(fW - ip - 1) & kBufMask];
            const float y = a + t * (b - a);

            fFbState += 0.3f * (y - fFbState);   // [feedback] a little darkening per repeat
            fBuf[fW] = softClip(fIn * in[i] + fFb * fFbState) + 1e-18f;   // [feedback] saturator + denormal guard
            fW = (fW + 1) & kBufMask;

            // [feedback] limit the wet only: the dry passes untouched, as it would through a pedal
            out[i] = fDry * in[i] + softKnee(fWet * y, 0.8f, 0.15f);
        }
    }

private:
    float fParams[kParameterCount];
    float fBuf[kBufSize];
    uint32_t fW = 0;
    float fSr = 48000.0f, fSmooth = 0.0f, fTimeSm = 0.0f;
    float fD = 16800.0f, fFb = 0.0f, fIn = 1.0f, fWet = 0.0f, fDry = 1.0f, fFbState = 0.0f;
    bool  fFirst = true;

    DISTRHO_DECLARE_NON_COPYABLE_WITH_LEAK_DETECTOR(SimpleEchoPlugin)
};

Plugin* createPlugin() { return new SimpleEchoPlugin(); }

END_NAMESPACE_DISTRHO
endef

define FACE_FETCH_TEST_FILE4
@prefix doap:   <http://usefulinc.com/ns/doap#> .
@prefix foaf:   <http://xmlns.com/foaf/0.1/> .
@prefix lv2:    <http://lv2plug.in/ns/lv2core#> .
@prefix pprops: <http://lv2plug.in/ns/ext/port-props#> .
@prefix rdfs:   <http://www.w3.org/2000/01/rdf-schema#> .
@prefix units:  <http://lv2plug.in/ns/extensions/units#> .

<urn:mod-cookbook:face-fetch-test>
    a lv2:Plugin , lv2:DelayPlugin ;
    doap:name "Face Fetch Test" ;
    doap:license <http://spdx.org/licenses/GPL-3.0-or-later.html> ;
    doap:maintainer [ foaf:name "MOD Cookbook" ] ;
    rdfs:comment "Template echo for the MOD plugin playbook." ;
    lv2:minorVersion 2 ;
    lv2:microVersion 0 ;
    lv2:optionalFeature lv2:hardRTCapable ;
    lv2:requiredFeature <http://lv2plug.in/ns/ext/options#options> ,
                        <http://lv2plug.in/ns/ext/urid#map> ;
    lv2:extensionData <http://lv2plug.in/ns/ext/options#interface> ;
    lv2:port [
        a lv2:InputPort , lv2:AudioPort ;
        lv2:index 0 ;
        lv2:symbol "in" ;
        lv2:name "In"
    ] , [
        a lv2:OutputPort , lv2:AudioPort ;
        lv2:index 1 ;
        lv2:symbol "out" ;
        lv2:name "Out"
    ] , [
        a lv2:InputPort , lv2:ControlPort ;
        lv2:index 2 ;
        lv2:symbol "time" ;
        lv2:name "Time" ;
        lv2:default 350 ;
        lv2:minimum 20 ;
        lv2:maximum 2000 ;
        lv2:portProperty pprops:logarithmic ;
        units:unit units:ms
    ] , [
        a lv2:InputPort , lv2:ControlPort ;
        lv2:index 3 ;
        lv2:symbol "feedback" ;
        lv2:name "Feedback" ;
        lv2:default 40 ;
        lv2:minimum 0 ;
        lv2:maximum 95 ;
        units:unit units:pc
    ] , [
        a lv2:InputPort , lv2:ControlPort ;
        lv2:index 4 ;
        lv2:symbol "mix" ;
        lv2:name "Mix" ;
        lv2:default 35 ;
        lv2:minimum 0 ;
        lv2:maximum 100 ;
        units:unit units:pc
    ] , [
        a lv2:InputPort , lv2:ControlPort ;
        lv2:index 5 ;
        lv2:symbol "tails" ;
        lv2:name "Tails" ;
        lv2:default 1 ;
        lv2:minimum 0 ;
        lv2:maximum 1 ;
        lv2:portProperty lv2:integer , lv2:toggled
    ] , [
        a lv2:InputPort , lv2:ControlPort ;
        lv2:index 6 ;
        lv2:symbol "lv2_enabled" ;
        lv2:name "Enabled" ;
        lv2:default 1 ;
        lv2:minimum 0 ;
        lv2:maximum 1 ;
        lv2:portProperty lv2:integer , lv2:toggled ;
        lv2:designation lv2:enabled
    ] .
endef

define FACE_FETCH_TEST_FILE5
@prefix lv2:  <http://lv2plug.in/ns/lv2core#> .
@prefix rdfs: <http://www.w3.org/2000/01/rdf-schema#> .

<urn:mod-cookbook:face-fetch-test>
    a lv2:Plugin , lv2:DelayPlugin ;
    lv2:binary <face-fetch-test_dsp.so> ;
    rdfs:seeAlso <face-fetch-test.ttl> , <modgui.ttl> .
endef

define FACE_FETCH_TEST_FILE6
@prefix lv2:    <http://lv2plug.in/ns/lv2core#> .
@prefix modgui: <http://moddevices.com/ns/modgui#> .

<urn:mod-cookbook:face-fetch-test>
    modgui:gui [
        modgui:resourcesDirectory <modgui> ;
        modgui:iconTemplate <modgui/icon-face-fetch-test.html> ;
        modgui:stylesheet <modgui/stylesheet-face-fetch-test.css> ;
        modgui:screenshot <modgui/screenshot-face-fetch-test.png> ;
        modgui:thumbnail <modgui/thumbnail-face-fetch-test.png> ;
        modgui:brand "MOD Cookbook" ;
        modgui:label "Face Fetch Test" ;
        modgui:model "japanese" ;
        modgui:panel "4-knobs" ;
        modgui:color "white" ;
        modgui:knob "black" ;
        modgui:port
        [ lv2:index 0 ; lv2:symbol "time" ; lv2:name "Time" ; ],
        [ lv2:index 1 ; lv2:symbol "feedback" ; lv2:name "Feedback" ; ],
        [ lv2:index 2 ; lv2:symbol "mix" ; lv2:name "Mix" ; ] ;
    ] .
endef

define FACE_FETCH_TEST_FILE7
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
AwC1uH6Zb+wF9gAAAABJRU5ErkJggg==
endef

define FACE_FETCH_TEST_FILE8
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
endef

export FACE_FETCH_TEST_SRC1
export FACE_FETCH_TEST_SRC2
export FACE_FETCH_TEST_SRC3

define FACE_FETCH_TEST_CONFIGURE_CMDS
	mkdir -p $(@D)/examples/face-fetch-test
	printf '%s\n' "$$FACE_FETCH_TEST_SRC1" > $(@D)/examples/face-fetch-test/DistrhoPluginInfo.h
	printf '%s\n' "$$FACE_FETCH_TEST_SRC2" > $(@D)/examples/face-fetch-test/Makefile
	printf '%s\n' "$$FACE_FETCH_TEST_SRC3" > $(@D)/examples/face-fetch-test/SimpleEchoPlugin.cpp
endef

define FACE_FETCH_TEST_BUILD_CMDS
	$(TARGET_MAKE_ENV) $(TARGET_CONFIGURE_OPTS) $(MAKE) NOOPT=true -C $(@D)/examples/face-fetch-test lv2_dsp
endef

define FACE_FETCH_TEST_INSTALL_TARGET_CMDS
	mkdir -p $($(PKG)_PKGDIR)/face-fetch-test.lv2
	cp $(@D)/bin/face-fetch-test.lv2/face-fetch-test_dsp.so $($(PKG)_PKGDIR)/face-fetch-test.lv2/
	$(file >$(@D)/.pb-1,$(FACE_FETCH_TEST_FILE4))
	cp $(@D)/.pb-1 $($(PKG)_PKGDIR)/face-fetch-test.lv2/face-fetch-test.ttl
	$(file >$(@D)/.pb-2,$(FACE_FETCH_TEST_FILE5))
	cp $(@D)/.pb-2 $($(PKG)_PKGDIR)/face-fetch-test.lv2/manifest.ttl
	$(file >$(@D)/.pb-3,$(FACE_FETCH_TEST_FILE6))
	cp $(@D)/.pb-3 $($(PKG)_PKGDIR)/face-fetch-test.lv2/modgui.ttl
	mkdir -p $($(PKG)_PKGDIR)/face-fetch-test.lv2/modgui
	$(file >$(@D)/.pb-4,$(FACE_FETCH_TEST_FILE7))
	base64 -d $(@D)/.pb-4 > $($(PKG)_PKGDIR)/face-fetch-test.lv2/modgui/screenshot-face-fetch-test.png
	mkdir -p $($(PKG)_PKGDIR)/face-fetch-test.lv2/modgui
	$(file >$(@D)/.pb-5,$(FACE_FETCH_TEST_FILE8))
	base64 -d $(@D)/.pb-5 > $($(PKG)_PKGDIR)/face-fetch-test.lv2/modgui/thumbnail-face-fetch-test.png
	mkdir -p $($(PKG)_PKGDIR)/face-fetch-test.lv2/modgui
	wget -q -O $($(PKG)_PKGDIR)/face-fetch-test.lv2/modgui/icon-face-fetch-test.html https://raw.githubusercontent.com/mod-audio/mod-sdk/ba1e9be87b7cb50cf18169649b2cffa9c7dd2c9d/html/resources/templates/pedal-japanese-4-knobs.html && test -s $($(PKG)_PKGDIR)/face-fetch-test.lv2/modgui/icon-face-fetch-test.html || (echo "face: could not download https://raw.githubusercontent.com/mod-audio/mod-sdk/ba1e9be87b7cb50cf18169649b2cffa9c7dd2c9d/html/resources/templates/pedal-japanese-4-knobs.html"; exit 1)
	mkdir -p $($(PKG)_PKGDIR)/face-fetch-test.lv2/modgui
	wget -q -O $($(PKG)_PKGDIR)/face-fetch-test.lv2/modgui/stylesheet-face-fetch-test.css https://raw.githubusercontent.com/mod-audio/mod-sdk/ba1e9be87b7cb50cf18169649b2cffa9c7dd2c9d/html/resources/pedals/japanese/japanese.css https://raw.githubusercontent.com/mod-audio/mod-sdk/ba1e9be87b7cb50cf18169649b2cffa9c7dd2c9d/html/resources/knobs/japanese/japanese.css && test -s $($(PKG)_PKGDIR)/face-fetch-test.lv2/modgui/stylesheet-face-fetch-test.css || (echo "face: could not download https://raw.githubusercontent.com/mod-audio/mod-sdk/ba1e9be87b7cb50cf18169649b2cffa9c7dd2c9d/html/resources/pedals/japanese/japanese.css https://raw.githubusercontent.com/mod-audio/mod-sdk/ba1e9be87b7cb50cf18169649b2cffa9c7dd2c9d/html/resources/knobs/japanese/japanese.css"; exit 1)
	mkdir -p $($(PKG)_PKGDIR)/face-fetch-test.lv2/modgui/knobs/japanese
	wget -q -O $($(PKG)_PKGDIR)/face-fetch-test.lv2/modgui/knobs/japanese/black.png https://raw.githubusercontent.com/mod-audio/mod-sdk/ba1e9be87b7cb50cf18169649b2cffa9c7dd2c9d/html/resources/knobs/japanese/black.png && test -s $($(PKG)_PKGDIR)/face-fetch-test.lv2/modgui/knobs/japanese/black.png || (echo "face: could not download https://raw.githubusercontent.com/mod-audio/mod-sdk/ba1e9be87b7cb50cf18169649b2cffa9c7dd2c9d/html/resources/knobs/japanese/black.png"; exit 1)
	mkdir -p $($(PKG)_PKGDIR)/face-fetch-test.lv2/modgui/pedals/japanese
	wget -q -O $($(PKG)_PKGDIR)/face-fetch-test.lv2/modgui/pedals/japanese/white.png https://raw.githubusercontent.com/mod-audio/mod-sdk/ba1e9be87b7cb50cf18169649b2cffa9c7dd2c9d/html/resources/pedals/japanese/white.png && test -s $($(PKG)_PKGDIR)/face-fetch-test.lv2/modgui/pedals/japanese/white.png || (echo "face: could not download https://raw.githubusercontent.com/mod-audio/mod-sdk/ba1e9be87b7cb50cf18169649b2cffa9c7dd2c9d/html/resources/pedals/japanese/white.png"; exit 1)
endef

$(eval $(generic-package))
