# Copyright (c) 2026 MOD Audio Limited
# SPDX-License-Identifier: MIT
#
# TEST RECIPE (MOD plugin playbook), based on the cookbook's gain.mk.
# Question: does builder.mod.audio fetch git submodules, the way MOD's own
# packages do (mod-plugin-builder's MOD_PLUGIN_BUILDER_DOWNLOAD_WITH_SUBMODULES)?
# Build fails with "SUBMODULE TEST FAILED" = no. Builds and installs "Submodule
# Test" (a gain plugin) = yes: path B repos can keep DPF as a git submodule
# instead of a vendored copy.
#
# A simple 1-in / 1-out gain plugin for the MOD Online Builder.
#
# Everything the plugin needs — DSP code, LV2 metadata, the DPF framework
# wrapper — is embedded directly into this single .mk file. No external
# source repository required. To build it, upload this file at
# https://builder.mod.audio/buildroot with a MOD unit connected over USB.
#
# How the embedding works:
#
#   - The plugin sources are stored as multi-line `define ... endef` make
#     variables (see the SUBMODULE_TEST_PLUGIN_CPP block below, etc.).
#   - `export` makes those variables available in the shell environment.
#   - At configure time, `printf '%s' "$$VAR" > path` writes each one out
#     to disk inside DPF's source tree, where DPF's build can pick it up.
#
# When the cloud builder receives this file, it rewrites every occurrence
# of `SUBMODULE_TEST_` to its own per-build project prefix (e.g. `TMPABC123_`). The
# rewrite is consistent across variable definitions and references, so
# everything keeps resolving correctly regardless of the rename.

SUBMODULE_TEST_VERSION = 61d38eb638449647fb8395a35c5b8dab7e981ba7
SUBMODULE_TEST_SITE = https://github.com/DISTRHO/DPF.git
SUBMODULE_TEST_SITE_METHOD = git
SUBMODULE_TEST_GIT_SUBMODULES = y
SUBMODULE_TEST_BUNDLES = submodule-test.lv2

# The test: MOD's own packages fetch git submodules with this hook from
# mod-plugin-builder. If the Online Builder has it, DPF's pugl submodule arrives.
SUBMODULE_TEST_PRE_DOWNLOAD_HOOKS += MOD_PLUGIN_BUILDER_DOWNLOAD_WITH_SUBMODULES

# ---------------------------------------------------------------------------
# Embedded plugin source
#
# A note on `$` characters: anything inside these define blocks is parsed by
# make first. If your DSP code needs a literal `$`, write `$$`. The plain
# gain code below has no `$`, so this is not an issue here.

define SUBMODULE_TEST_PLUGIN_CPP
#include "DistrhoPlugin.hpp"

START_NAMESPACE_DISTRHO

/*
 * Simple mono gain plugin. One audio in, one audio out, one parameter
 * controlling output amplitude.
 */
class GainPlugin : public Plugin
{
public:
    GainPlugin()
        : Plugin(kParameterCount, 0, 0),
          fGain(1.0f)
    {
    }

protected:
    const char* getLabel()       const override { return "SubmoduleTest"; }
    const char* getDescription() const override { return "Simple mono gain plugin."; }
    const char* getMaker()       const override { return "MOD"; }
    const char* getHomePage()    const override { return "https://mod.audio"; }
    const char* getLicense()     const override { return "MIT"; }
    uint32_t    getVersion()     const override { return d_version(1, 0, 0); }
    int64_t     getUniqueId()    const override { return d_cconst('s', 'M', 't', '1'); }

    void initParameter(uint32_t index, Parameter& parameter) override
    {
        if (index == kGain) {
            parameter.hints      = kParameterIsAutomatable;
            parameter.name       = "Gain";
            parameter.symbol     = "gain";
            parameter.unit       = "x";
            parameter.ranges.def = 1.0f;
            parameter.ranges.min = 0.0f;
            parameter.ranges.max = 4.0f;
        }
    }

    float getParameterValue(uint32_t index) const override
    {
        return (index == kGain) ? fGain : 0.0f;
    }

    void setParameterValue(uint32_t index, float value) override
    {
        if (index == kGain) fGain = value;
    }

    void run(const float** inputs, float** outputs, uint32_t frames) override
    {
        const float* in   = inputs[0];
        float*       out  = outputs[0];
        const float  gain = fGain;
        for (uint32_t i = 0; i < frames; ++i)
            out[i] = in[i] * gain;
    }

private:
    float fGain;

    DISTRHO_DECLARE_NON_COPYABLE_WITH_LEAK_DETECTOR(GainPlugin)
};

Plugin* createPlugin() { return new GainPlugin(); }

END_NAMESPACE_DISTRHO
endef

define SUBMODULE_TEST_PLUGIN_INFO_H
#ifndef DISTRHO_PLUGIN_INFO_H_INCLUDED
#define DISTRHO_PLUGIN_INFO_H_INCLUDED

#define DISTRHO_PLUGIN_BRAND       "MOD"
#define DISTRHO_PLUGIN_NAME        "Submodule Test"
#define DISTRHO_PLUGIN_URI         "urn:mod-cookbook:submodule-test"

#define DISTRHO_PLUGIN_HAS_UI       0
#define DISTRHO_PLUGIN_IS_RT_SAFE   1
#define DISTRHO_PLUGIN_NUM_INPUTS   1
#define DISTRHO_PLUGIN_NUM_OUTPUTS  1

enum Parameters {
    kGain = 0,
    kParameterCount
};

#endif
endef

define SUBMODULE_TEST_PLUGIN_MAKEFILE
#!/usr/bin/make -f
NAME = submodule-test
FILES_DSP = GainPlugin.cpp
include ../../Makefile.plugins.mk
TARGETS = lv2_dsp
all: $$(TARGETS)
endef

# LV2 turtle (.ttl) metadata is normally generated by DPF running a small
# native helper against the compiled .so. That helper cannot run when
# cross-compiling for ARM without a qemu emulator, which the MOD builder
# image doesn't provide. So we hand-write the .ttl files here instead.
# They must stay consistent with what the C++ above declares:
#   - The URI must match DISTRHO_PLUGIN_URI.
#   - The lv2:binary must match the compiled .so name (NAME_dsp.so).
#   - The port indices and ranges must match initParameter() / NUM_INPUTS.

define SUBMODULE_TEST_MANIFEST_TTL
@prefix lv2:  <http://lv2plug.in/ns/lv2core#> .
@prefix rdfs: <http://www.w3.org/2000/01/rdf-schema#> .

<urn:mod-cookbook:submodule-test>
    a lv2:Plugin , lv2:AmplifierPlugin ;
    lv2:binary <submodule-test_dsp.so> ;
    rdfs:seeAlso <submodule-test.ttl> .
endef

define SUBMODULE_TEST_PLUGIN_TTL
@prefix doap:  <http://usefulinc.com/ns/doap#> .
@prefix foaf:  <http://xmlns.com/foaf/0.1/> .
@prefix lv2:   <http://lv2plug.in/ns/lv2core#> .
@prefix rdfs:  <http://www.w3.org/2000/01/rdf-schema#> .
@prefix units: <http://lv2plug.in/ns/extensions/units#> .

<urn:mod-cookbook:submodule-test>
    a lv2:Plugin , lv2:AmplifierPlugin ;
    doap:name "Submodule Test" ;
    doap:license <http://opensource.org/licenses/MIT> ;
    doap:maintainer [
        foaf:name "MOD" ;
        foaf:homepage <https://mod.audio>
    ] ;
    rdfs:comment "Simple mono gain plugin." ;
    lv2:port [
        a lv2:InputPort , lv2:AudioPort ;
        lv2:index 0 ;
        lv2:symbol "in" ;
        lv2:name "Audio In"
    ] , [
        a lv2:OutputPort , lv2:AudioPort ;
        lv2:index 1 ;
        lv2:symbol "out" ;
        lv2:name "Audio Out"
    ] , [
        a lv2:InputPort , lv2:ControlPort ;
        lv2:index 2 ;
        lv2:symbol "gain" ;
        lv2:name "Gain" ;
        lv2:default 1.0 ;
        lv2:minimum 0.0 ;
        lv2:maximum 4.0 ;
        units:unit units:coef
    ] .
endef

export SUBMODULE_TEST_PLUGIN_CPP
export SUBMODULE_TEST_PLUGIN_INFO_H
export SUBMODULE_TEST_PLUGIN_MAKEFILE
export SUBMODULE_TEST_MANIFEST_TTL
export SUBMODULE_TEST_PLUGIN_TTL

# ---------------------------------------------------------------------------
# Buildroot lifecycle hooks

define SUBMODULE_TEST_CONFIGURE_CMDS
	test -e $(@D)/dgl/src/pugl-upstream/COPYING || (echo "SUBMODULE TEST FAILED: the pugl submodule was not fetched, so this builder does not run the submodule hook"; exit 1)
	echo "SUBMODULE TEST PASSED: git submodules are fetched on this builder"
	mkdir -p $(@D)/examples/submodule-test
	printf '%s' "$$SUBMODULE_TEST_PLUGIN_CPP"      > $(@D)/examples/submodule-test/GainPlugin.cpp
	printf '%s' "$$SUBMODULE_TEST_PLUGIN_INFO_H"   > $(@D)/examples/submodule-test/DistrhoPluginInfo.h
	printf '%s' "$$SUBMODULE_TEST_PLUGIN_MAKEFILE" > $(@D)/examples/submodule-test/Makefile
endef

define SUBMODULE_TEST_BUILD_CMDS
	$(TARGET_MAKE_ENV) $(TARGET_CONFIGURE_OPTS) $(MAKE) NOOPT=true -C $(@D)/examples/submodule-test lv2_dsp
endef

define SUBMODULE_TEST_INSTALL_TARGET_CMDS
	mkdir -p $($(PKG)_PKGDIR)/submodule-test.lv2
	cp $(@D)/bin/submodule-test.lv2/submodule-test_dsp.so $($(PKG)_PKGDIR)/submodule-test.lv2/
	printf '%s' "$$SUBMODULE_TEST_MANIFEST_TTL" > $($(PKG)_PKGDIR)/submodule-test.lv2/manifest.ttl
	printf '%s' "$$SUBMODULE_TEST_PLUGIN_TTL"   > $($(PKG)_PKGDIR)/submodule-test.lv2/submodule-test.ttl
endef

$(eval $(generic-package))
