// Simple Echo: the playbook's template plugin. Small on purpose, but it uses
// every pattern the playbook asks for:
//   - all memory allocated up front, sized for 96 kHz; run() never allocates
//   - controls snapped on the first run(), smoothed after that
//   - in-plugin bypass with Tails on/off (lv2:enabled port, last)
//   - denormal guard in the feedback path
//   - a soft knee on the output, so nothing hard-clips at the converter
#include "DistrhoPlugin.hpp"

#include <cmath>
#include <cstring>
#include <cstdint>

START_NAMESPACE_DISTRHO

static const uint32_t kBufSize = 1u << 18;      // 2.7 s at 96 kHz
static const uint32_t kBufMask = kBufSize - 1;

static inline float clampf(float x, float lo, float hi) { return x < lo ? lo : (x > hi ? hi : x); }
static inline float onePoleCoef(float hz, float sr) { return 1.0f - std::exp(-6.2831853f * hz / sr); }

// rational tanh: smooth, flat beyond |x| = 3, no libm call per sample
static inline float softClip(float x)
{
    if (x >  3.0f) return  1.0f;
    if (x < -3.0f) return -1.0f;
    const float x2 = x * x;
    return x * (27.0f + x2) / (27.0f + 9.0f * x2);
}

// linear below k, approaches k + r smoothly, never above it
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
    const char* getDescription() const override { return "Template echo for the MOD plugin playbook."; }
    const char* getMaker()       const override { return DISTRHO_PLUGIN_BRAND; }
    const char* getLicense()     const override { return "GPL-3.0-or-later"; }
    uint32_t    getVersion()     const override { return d_version(1, 0, 0); }   // = lv2:minorVersion 2, microVersion 0
    int64_t     getUniqueId()    const override { return d_cconst('s', 'E', 'c', 'o'); }

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
        case kTails:
            p.hints |= kParameterIsInteger | kParameterIsBoolean;
            p.name = "Tails"; p.symbol = "tails";
            p.ranges.min = 0.0f; p.ranges.max = 1.0f; p.ranges.def = 1.0f;
            break;
        case kBypass:
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
        const float inT      = bypass ? 0.0f : 1.0f;
        const float wetT     = (bypass && !tails) ? 0.0f : mix;
        const float dryT     = bypass ? 1.0f : 1.0f - mix;

        if (fFirst) {                    // controls arrive with the first run()
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

            fFbState += 0.3f * (y - fFbState);   // a little darkening per repeat
            fBuf[fW] = softClip(fIn * in[i] + fFb * fFbState) + 1e-18f;   // denormal guard
            fW = (fW + 1) & kBufMask;

            out[i] = softKnee(fDry * in[i] + fWet * y, 0.89f, 0.1f);
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
