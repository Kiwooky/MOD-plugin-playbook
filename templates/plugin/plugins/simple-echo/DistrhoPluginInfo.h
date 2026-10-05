#ifndef DISTRHO_PLUGIN_INFO_H_INCLUDED
#define DISTRHO_PLUGIN_INFO_H_INCLUDED

// Rename these together with the TTL (see docs/lv2-and-mod-rules.md).
#define DISTRHO_PLUGIN_BRAND       "MOD Cookbook"
#define DISTRHO_PLUGIN_NAME        "Simple Echo"
#define DISTRHO_PLUGIN_URI         "urn:mod-cookbook:simple-echo"

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
