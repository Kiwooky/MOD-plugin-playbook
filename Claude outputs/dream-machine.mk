# DREAM MACHINE — Niels
# Siamese Dream-inspired op-amp Big Muff character with switchable octave-up fuzz.
# Single-file recipe for https://builder.mod.audio/buildroot
#
# Build 2 (1.0.1): fixes manifest.ttl. It pointed to the plugin's description with
# lv2:seeAlso instead of rdfs:seeAlso, so MOD never read dream-machine.ttl: the
# plugin showed up with no name, category or controls, and couldn't be removed.

DREAM_MACHINE_VERSION = 61d38eb638449647fb8395a35c5b8dab7e981ba7
DREAM_MACHINE_SITE = https://github.com/DISTRHO/DPF.git
DREAM_MACHINE_SITE_METHOD = git
DREAM_MACHINE_BUNDLES = dream-machine.lv2

define DREAM_MACHINE_PLUGIN_INFO_H
#ifndef DISTRHO_PLUGIN_INFO_H_INCLUDED
#define DISTRHO_PLUGIN_INFO_H_INCLUDED
#define DISTRHO_PLUGIN_BRAND "Niels"
#define DISTRHO_PLUGIN_NAME "DREAM MACHINE"
#define DISTRHO_PLUGIN_URI "urn:mod-cookbook:dream-machine"
#define DISTRHO_PLUGIN_HAS_UI 0
#define DISTRHO_PLUGIN_IS_RT_SAFE 1
#define DISTRHO_PLUGIN_NUM_INPUTS 1
#define DISTRHO_PLUGIN_NUM_OUTPUTS 1
enum Parameters {
    kSustain = 0,
    kTone,
    kVolume,
    kOctave,
    kBypass,
    kParameterCount
};
#endif
endef

define DREAM_MACHINE_PLUGIN_MAKEFILE
#!/usr/bin/make -f
NAME = dream-machine
FILES_DSP = DreamMachinePlugin.cpp
include ../../Makefile.plugins.mk
TARGETS = lv2_dsp
all: $$(TARGETS)
endef

define DREAM_MACHINE_PLUGIN_CPP
#include "DistrhoPlugin.hpp"
#include <cmath>
#include <cstdint>

START_NAMESPACE_DISTRHO

static inline float clampf(float x, float lo, float hi)
{
    return x < lo ? lo : (x > hi ? hi : x);
}

static inline float onePole(float hz, float sr)
{
    return 1.0f - std::exp(-6.28318530718f * hz / sr);
}

// Smooth, bounded waveshaper used for the cascaded fuzz stages.
static inline float fuzzClip(float x)
{
    const float a = std::fabs(x);
    if (a > 3.0f) return x < 0.0f ? -1.0f : 1.0f;
    const float x2 = x * x;
    return x * (27.0f + x2) / (27.0f + 9.0f * x2);
}

class DreamMachinePlugin : public Plugin
{
public:
    DreamMachinePlugin() : Plugin(kParameterCount, 0, 0)
    {
        fParams[kSustain] = 78.0f;
        fParams[kTone] = 55.0f;
        fParams[kVolume] = 50.0f;
        fParams[kOctave] = 0.0f;
        fParams[kBypass] = 0.0f;
    }

protected:
    const char* getLabel() const override { return "DREAM MACHINE"; }
    const char* getDescription() const override { return "Op-amp Big Muff-inspired fuzz with switchable octave-up mode."; }
    const char* getMaker() const override { return DISTRHO_PLUGIN_BRAND; }
    const char* getLicense() const override { return "MIT"; }
    uint32_t getVersion() const override { return d_version(1, 0, 1); }
    int64_t getUniqueId() const override { return d_cconst('N', 'D', 'M', '1'); }

    void initParameter(uint32_t index, Parameter& p) override
    {
        p.hints = kParameterIsAutomatable;
        switch (index) {
        case kSustain:
            p.name = "Sustain"; p.symbol = "sustain"; p.unit = "%";
            p.ranges.min = 0.0f; p.ranges.max = 100.0f; p.ranges.def = 78.0f;
            break;
        case kTone:
            p.name = "Tone"; p.symbol = "tone"; p.unit = "%";
            p.ranges.min = 0.0f; p.ranges.max = 100.0f; p.ranges.def = 55.0f;
            break;
        case kVolume:
            p.name = "Volume"; p.symbol = "volume"; p.unit = "%";
            p.ranges.min = 0.0f; p.ranges.max = 100.0f; p.ranges.def = 50.0f;
            break;
        case kOctave:
            p.hints |= kParameterIsInteger | kParameterIsBoolean;
            p.name = "Octave"; p.symbol = "octave";
            p.ranges.min = 0.0f; p.ranges.max = 1.0f; p.ranges.def = 0.0f;
            break;
        case kBypass:
            p.initDesignation(kParameterDesignationBypass);
            break;
        }
    }

    float getParameterValue(uint32_t i) const override
    {
        return i < kParameterCount ? fParams[i] : 0.0f;
    }

    void setParameterValue(uint32_t i, float v) override
    {
        if (i < kParameterCount) fParams[i] = v;
    }

    void activate() override
    {
        fSr = static_cast<float>(getSampleRate());
        fSmooth = onePole(30.0f, fSr);
        fInHpCoef = onePole(110.0f, fSr * 4.0f);
        fToneLowCoef = onePole(720.0f, fSr * 4.0f);
        fToneHighCoef = onePole(1150.0f, fSr * 4.0f);
        fPostCoef = onePole(8500.0f, fSr * 4.0f);
        fInputLow = fToneLow = fToneHigh = fPost = 0.0f;
        fPrevInput = 0.0f;
        fFirst = true;
        fTone = 55.0f;
        fVolume = 1.0f;
        fDrive = std::pow(10.0f, 0.40f + (78.0f * 0.016f));
        fOctave = 0.0f;
        fBypass = 0.0f;
    }

    void run(const float** inputs, float** outputs, uint32_t frames) override
    {
        const float* in = inputs[0];
        float* out = outputs[0];
        const float sustainTarget = clampf(fParams[kSustain], 0.0f, 100.0f);
        const float toneTarget = clampf(fParams[kTone], 0.0f, 100.0f);
        const float volumeTarget = clampf(fParams[kVolume] * 0.02f, 0.0f, 2.0f);
        const float driveTarget = std::pow(10.0f, 0.40f + (sustainTarget * 0.016f));
        const float octaveTarget = fParams[kOctave] > 0.5f ? 1.0f : 0.0f;
        const float bypassTarget = fParams[kBypass] > 0.5f ? 1.0f : 0.0f;

        if (fFirst) {
            fTone = toneTarget;
            fVolume = volumeTarget;
            fDrive = driveTarget;
            fOctave = octaveTarget;
            fBypass = bypassTarget;
            fFirst = false;
        }

        for (uint32_t i = 0; i < frames; ++i) {
            fTone += fSmooth * (toneTarget - fTone);
            fVolume += fSmooth * (volumeTarget - fVolume);
            fDrive += fSmooth * (driveTarget - fDrive);
            fOctave += fSmooth * (octaveTarget - fOctave);
            fBypass += fSmooth * (bypassTarget - fBypass);

            const float x = in[i];
            // 4x linear-interpolated oversampling keeps the high-gain clipping
            // stages cleaner; the post low-pass and 4-sample average decimate.
            const float drive = fDrive;
            float effected = 0.0f;
            for (uint32_t os = 0; os < 4; ++os) {
                const float frac = 0.25f * static_cast<float>(os + 1);
                const float sub = fPrevInput + (x - fPrevInput) * frac;

                // Input high-pass keeps low strings tight at high Sustain settings.
                fInputLow += fInHpCoef * (sub - fInputLow);
                const float hp = sub - fInputLow;

                // Full-wave rectification creates strong second-harmonic energy.
                // A little original waveform remains for a more playable octave-fuzz texture.
                const float rectified = std::fabs(hp);
                const float octaveSignal = 0.78f * rectified + 0.22f * hp;
                const float source = hp + fOctave * (octaveSignal - hp);

                // Two cascaded, op-amp-style clipping stages.
                const float stage1 = fuzzClip(source * drive * 1.35f);
                const float stage2 = fuzzClip(stage1 * 2.10f);
                const float stage3 = fuzzClip(stage2 * 1.85f);

                // Big-Muff-inspired low/high tone blend with a scooped centre.
                fToneLow += fToneLowCoef * (stage3 - fToneLow);
                fToneHigh += fToneHighCoef * (stage3 - fToneHigh);
                const float lowBand = fToneLow;
                const float highBand = stage3 - fToneHigh;
                const float bright = fTone * 0.01f;
                const float shaped = (1.0f - bright) * lowBand + bright * highBand;

                fPost += fPostCoef * (shaped - fPost);
                effected += fPost * fVolume * 0.25f;
            }
            fPrevInput = x;
            // ~10 ms in-plugin bypass fade; no limiter after the fuzz curve.
            const float wet = effected * (1.0f - fBypass);
            out[i] = wet + x * fBypass;
        }
    }

private:
    float fParams[kParameterCount];
    float fSr = 48000.0f;
    float fSmooth = 0.0f;
    float fInHpCoef = 0.0f, fToneLowCoef = 0.0f, fToneHighCoef = 0.0f, fPostCoef = 0.0f;
    float fInputLow = 0.0f, fToneLow = 0.0f, fToneHigh = 0.0f, fPost = 0.0f, fPrevInput = 0.0f;
    float fTone = 55.0f, fVolume = 1.0f, fDrive = 0.0f, fOctave = 0.0f, fBypass = 0.0f;
    bool fFirst = true;
    DISTRHO_DECLARE_NON_COPYABLE_WITH_LEAK_DETECTOR(DreamMachinePlugin)
};

Plugin* createPlugin() { return new DreamMachinePlugin(); }
END_NAMESPACE_DISTRHO
endef

define DREAM_MACHINE_MANIFEST_TTL
@prefix lv2:  <http://lv2plug.in/ns/lv2core#> .
@prefix rdfs: <http://www.w3.org/2000/01/rdf-schema#> .

<urn:mod-cookbook:dream-machine>
    a lv2:Plugin , lv2:DistortionPlugin ;
    lv2:binary <dream-machine_dsp.so> ;
    rdfs:seeAlso <dream-machine.ttl> .
endef

define DREAM_MACHINE_PLUGIN_TTL
@prefix doap: <http://usefulinc.com/ns/doap#> .
@prefix foaf: <http://xmlns.com/foaf/0.1/> .
@prefix lv2: <http://lv2plug.in/ns/lv2core#> .
@prefix pprops: <http://lv2plug.in/ns/ext/port-props#> .
@prefix rdfs: <http://www.w3.org/2000/01/rdf-schema#> .
@prefix units: <http://lv2plug.in/ns/extensions/units#> .

<urn:mod-cookbook:dream-machine>
    a lv2:Plugin, lv2:DistortionPlugin ;
    doap:name "DREAM MACHINE" ;
    doap:license <http://spdx.org/licenses/MIT.html> ;
    doap:maintainer [ foaf:name "Niels" ] ;
    rdfs:comment "Siamese Dream-inspired op-amp fuzz with switchable octave-up mode." ;
    lv2:minorVersion 2 ;
    lv2:microVersion 1 ;
    lv2:optionalFeature lv2:hardRTCapable ;
    lv2:requiredFeature <http://lv2plug.in/ns/ext/options#options>, <http://lv2plug.in/ns/ext/urid#map> ;
    lv2:extensionData <http://lv2plug.in/ns/ext/options#interface> ;
    lv2:port [ a lv2:InputPort, lv2:AudioPort ; lv2:index 0 ; lv2:symbol "in" ; lv2:name "In" ],
             [ a lv2:OutputPort, lv2:AudioPort ; lv2:index 1 ; lv2:symbol "out" ; lv2:name "Out" ],
             [ a lv2:InputPort, lv2:ControlPort ; lv2:index 2 ; lv2:symbol "sustain" ; lv2:name "Sustain" ; lv2:default 78 ; lv2:minimum 0 ; lv2:maximum 100 ; units:unit units:pc ],
             [ a lv2:InputPort, lv2:ControlPort ; lv2:index 3 ; lv2:symbol "tone" ; lv2:name "Tone" ; lv2:default 55 ; lv2:minimum 0 ; lv2:maximum 100 ; units:unit units:pc ],
             [ a lv2:InputPort, lv2:ControlPort ; lv2:index 4 ; lv2:symbol "volume" ; lv2:name "Volume" ; lv2:default 50 ; lv2:minimum 0 ; lv2:maximum 100 ; units:unit units:pc ],
             [ a lv2:InputPort, lv2:ControlPort ; lv2:index 5 ; lv2:symbol "octave" ; lv2:name "Octave" ; lv2:default 0 ; lv2:minimum 0 ; lv2:maximum 1 ; lv2:portProperty lv2:integer, lv2:toggled ],
             [ a lv2:InputPort, lv2:ControlPort ; lv2:index 6 ; lv2:symbol "lv2_enabled" ; lv2:name "Enabled" ; lv2:default 1 ; lv2:minimum 0 ; lv2:maximum 1 ; lv2:portProperty lv2:integer, lv2:toggled ; lv2:designation lv2:enabled ] .
endef

export DREAM_MACHINE_PLUGIN_CPP
export DREAM_MACHINE_PLUGIN_INFO_H
export DREAM_MACHINE_PLUGIN_MAKEFILE
export DREAM_MACHINE_MANIFEST_TTL
export DREAM_MACHINE_PLUGIN_TTL

define DREAM_MACHINE_CONFIGURE_CMDS
mkdir -p $(@D)/examples/dream-machine
printf '%s' "$$DREAM_MACHINE_PLUGIN_INFO_H" > $(@D)/examples/dream-machine/DistrhoPluginInfo.h
printf '%s' "$$DREAM_MACHINE_PLUGIN_MAKEFILE" > $(@D)/examples/dream-machine/Makefile
printf '%s' "$$DREAM_MACHINE_PLUGIN_CPP" > $(@D)/examples/dream-machine/DreamMachinePlugin.cpp
endef

define DREAM_MACHINE_BUILD_CMDS
$(TARGET_MAKE_ENV) $(TARGET_CONFIGURE_OPTS) $(MAKE) NOOPT=true -C $(@D)/examples/dream-machine lv2_dsp
endef

define DREAM_MACHINE_INSTALL_TARGET_CMDS
mkdir -p $($(PKG)_PKGDIR)/dream-machine.lv2
cp $(@D)/bin/dream-machine.lv2/dream-machine_dsp.so $($(PKG)_PKGDIR)/dream-machine.lv2/
$(file >$(@D)/.dream-manifest,$(DREAM_MACHINE_MANIFEST_TTL))
cp $(@D)/.dream-manifest $($(PKG)_PKGDIR)/dream-machine.lv2/manifest.ttl
$(file >$(@D)/.dream-plugin,$(DREAM_MACHINE_PLUGIN_TTL))
cp $(@D)/.dream-plugin $($(PKG)_PKGDIR)/dream-machine.lv2/dream-machine.ttl
endef

$(eval $(generic-package))
