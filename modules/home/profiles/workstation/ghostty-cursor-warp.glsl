// Adapted from cursor_warp.glsl in https://github.com/sahaj-b/ghostty-cursor-shaders
// (commit 9ad9158a93c0de0c045e1c6b27df37da698bc8af) for Ghostty 1.4+:
// - Animates every real cursor move while skipping empty initial cursors, in-place
//   size/style changes, and moves during the focus-in window.
// - Adds a horizontal warp-collapse cue when a pane gains focus.
// - Adds an idle early-exit and fixes upstream's effectiveBlur shadowing and pow() domain.
//
// MIT License
//
// Copyright (c) 2026 Sahaj Bhatt
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

// --- CONFIGURATION ---
const float DURATION = 0.2;           // cursor warp duration in seconds
const float TRAIL_SIZE = 0.8;         // 0.0 = rigid move, 1.0 = max smear
const float BLUR = 1.0;               // antialiasing blur in pixels
const float TRAIL_THICKNESS = 1.0;    // vertical scale relative to cursor height
const float TRAIL_THICKNESS_X = 0.9;  // horizontal scale relative to cursor width

const float FOCUS_DURATION = 0.24;    // focus-in collapse duration in seconds
const float FOCUS_SPREAD = 1.25;      // max horizontal half-width in cursor heights
const float FOCUS_OPACITY = 0.9;      // peak alpha on focus gain

// Ghostty passes sRGB cursor colors, while the shader pipeline blends in linear space.
vec3 sRGBToLinear(vec3 c) {
    return mix(c / 12.92, pow((c + 0.055) / 1.055, vec3(2.4)), step(vec3(0.04045), c));
}

// EaseOutCirc
float ease(float x) {
    float t = x - 1.0;
    return sqrt(max(0.0, 1.0 - t * t));
}

vec2 toNormalized(vec2 value, float isPosition) {
    return (value * 2.0 - iResolution.xy * isPosition) / iResolution.y;
}

float antialias(float distance, float blurPixels) {
    if (blurPixels <= 0.0) {
        return step(distance, 0.0);
    }
    float width = toNormalized(vec2(blurPixels), 0.0).x;
    return 1.0 - smoothstep(0.0, width, distance);
}

float getSdfRectangle(in vec2 p, in vec2 center, in vec2 halfSize) {
    vec2 d = abs(p - center) - halfSize;
    return length(max(d, 0.0)) + min(max(d.x, d.y), 0.0);
}

// Based on Inigo Quilez's 2D polygon SDF: https://iquilezles.org/articles/distfunctions2d/
float seg(in vec2 p, in vec2 a, in vec2 b, inout float s, float d) {
    vec2 e = b - a;
    vec2 w = p - a;
    vec2 proj = a + e * clamp(dot(w, e) / max(dot(e, e), 1e-12), 0.0, 1.0);
    float segd = dot(p - proj, p - proj);
    d = min(d, segd);

    float c0 = step(0.0, p.y - a.y);
    float c1 = 1.0 - step(0.0, p.y - b.y);
    float c2 = 1.0 - step(0.0, e.x * w.y - e.y * w.x);
    float allCond = c0 * c1 * c2;
    float noneCond = (1.0 - c0) * (1.0 - c1) * (1.0 - c2);
    s *= mix(1.0, -1.0, step(0.5, allCond + noneCond));
    return d;
}

float getSdfConvexQuad(in vec2 p, in vec2 v1, in vec2 v2, in vec2 v3, in vec2 v4) {
    float s = 1.0;
    float d = dot(p - v1, p - v1);

    d = seg(p, v1, v2, s, d);
    d = seg(p, v2, v3, s, d);
    d = seg(p, v3, v4, s, d);
    d = seg(p, v4, v1, s, d);

    return s * sqrt(d);
}

// Maps corner-to-movement alignment dotVal in [-2, 2] to lead / side / trail duration.
float getDurationFromDot(float dotVal, float lead, float side, float trail) {
    float isLead = step(0.5, dotVal);
    float isSide = step(-0.5, dotVal) * (1.0 - isLead);
    float duration = mix(trail, side, isSide);
    return mix(duration, lead, isLead);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec4 baseColor = texture(iChannel0, fragCoord / iResolution.xy);

    float moveAge = iTime - iTimeCursorChange;
    float focusAge = iTime - iTimeFocus;

    bool showMove =
        iPreviousCursor.w > 0.0 &&
        distance(iCurrentCursor.xy, iPreviousCursor.xy) > 0.5 &&
        iTimeCursorChange >= iTimeFocus + FOCUS_DURATION &&
        moveAge >= 0.0 &&
        moveAge < DURATION - 0.001;

    bool showFocus =
        iFocus != 0 &&
        iCursorVisible != 0 &&
        iCurrentCursor.w > 0.0 &&
        focusAge >= 0.0 &&
        focusAge < FOCUS_DURATION;

    if (!showMove && !showFocus) {
        fragColor = baseColor;
        return;
    }

    vec4 trailColor = vec4(sRGBToLinear(iCurrentCursorColor.rgb), iCurrentCursorColor.a);
    vec2 vu = toNormalized(fragCoord, 1.0);

    vec4 currentCursor = vec4(toNormalized(iCurrentCursor.xy, 1.0), toNormalized(iCurrentCursor.zw, 0.0));
    vec2 halfSizeCC = currentCursor.zw * 0.5;
    vec2 centerCC = currentCursor.xy + vec2(halfSizeCC.x, -halfSizeCC.y);
    float sdfCurrentCursor = getSdfRectangle(vu, centerCC, halfSizeCC);

    vec4 outColor = baseColor;

    if (showMove) {
        vec4 previousCursor = vec4(toNormalized(iPreviousCursor.xy, 1.0), toNormalized(iPreviousCursor.zw, 0.0));
        vec2 halfSizeCP = previousCursor.zw * 0.5;
        vec2 centerCP = previousCursor.xy + vec2(halfSizeCP.x, -halfSizeCP.y);

        vec2 ccHalf = halfSizeCC * vec2(TRAIL_THICKNESS_X, TRAIL_THICKNESS);
        vec2 cpHalf = halfSizeCP * vec2(TRAIL_THICKNESS_X, TRAIL_THICKNESS);

        vec2 cc_tl = centerCC + vec2(-ccHalf.x,  ccHalf.y);
        vec2 cc_tr = centerCC + vec2( ccHalf.x,  ccHalf.y);
        vec2 cc_bl = centerCC + vec2(-ccHalf.x, -ccHalf.y);
        vec2 cc_br = centerCC + vec2( ccHalf.x, -ccHalf.y);

        vec2 cp_tl = centerCP + vec2(-cpHalf.x,  cpHalf.y);
        vec2 cp_tr = centerCP + vec2( cpHalf.x,  cpHalf.y);
        vec2 cp_bl = centerCP + vec2(-cpHalf.x, -cpHalf.y);
        vec2 cp_br = centerCP + vec2( cpHalf.x, -cpHalf.y);

        const float DURATION_TRAIL = DURATION;
        const float DURATION_LEAD = DURATION * (1.0 - TRAIL_SIZE);
        const float DURATION_SIDE = (DURATION_LEAD + DURATION_TRAIL) * 0.5;

        vec2 s = sign(centerCC - centerCP);

        float dot_tl = dot(vec2(-1.0,  1.0), s);
        float dot_tr = dot(vec2( 1.0,  1.0), s);
        float dot_bl = dot(vec2(-1.0, -1.0), s);
        float dot_br = dot(vec2( 1.0, -1.0), s);

        float dur_tl = getDurationFromDot(dot_tl, DURATION_LEAD, DURATION_SIDE, DURATION_TRAIL);
        float dur_tr = getDurationFromDot(dot_tr, DURATION_LEAD, DURATION_SIDE, DURATION_TRAIL);
        float dur_bl = getDurationFromDot(dot_bl, DURATION_LEAD, DURATION_SIDE, DURATION_TRAIL);
        float dur_br = getDurationFromDot(dot_br, DURATION_LEAD, DURATION_SIDE, DURATION_TRAIL);

        // Keep vertical leading/trailing edges aligned on horizontal moves.
        float isMovingRight = step(0.5, s.x);
        float isMovingLeft = step(0.5, -s.x);
        float dur_right_rail = getDurationFromDot((dot_tr + dot_br) * 0.5, DURATION_LEAD, DURATION_SIDE, DURATION_TRAIL);
        float dur_left_rail = getDurationFromDot((dot_tl + dot_bl) * 0.5, DURATION_LEAD, DURATION_SIDE, DURATION_TRAIL);

        float final_dur_tl = mix(dur_tl, dur_left_rail, isMovingLeft);
        float final_dur_bl = mix(dur_bl, dur_left_rail, isMovingLeft);
        float final_dur_tr = mix(dur_tr, dur_right_rail, isMovingRight);
        float final_dur_br = mix(dur_br, dur_right_rail, isMovingRight);

        vec2 v_tl = mix(cp_tl, cc_tl, ease(clamp(moveAge / final_dur_tl, 0.0, 1.0)));
        vec2 v_tr = mix(cp_tr, cc_tr, ease(clamp(moveAge / final_dur_tr, 0.0, 1.0)));
        vec2 v_br = mix(cp_br, cc_br, ease(clamp(moveAge / final_dur_br, 0.0, 1.0)));
        vec2 v_bl = mix(cp_bl, cc_bl, ease(clamp(moveAge / final_dur_bl, 0.0, 1.0)));

        float sdfTrail = getSdfConvexQuad(vu, v_tl, v_tr, v_br, v_bl);

        float effectiveBlur = BLUR;
        if (BLUR < 2.5) {
            float isDiagonal = abs(s.x) * abs(s.y);
            effectiveBlur = mix(0.0, BLUR, isDiagonal);
        }
        float shapeAlpha = antialias(sdfTrail, effectiveBlur);

        outColor = mix(outColor, vec4(trailColor.rgb, outColor.a), trailColor.a * shapeAlpha);
    }

    if (showFocus) {
        float focusEase = ease(clamp(focusAge / FOCUS_DURATION, 0.0, 1.0));
        float fade = 1.0 - focusEase;

        vec2 rel = abs(vu - centerCC);
        float halfW = halfSizeCC.x + fade * currentCursor.w * FOCUS_SPREAD;
        float halfH = halfSizeCC.y * mix(0.92, 1.0, focusEase);

        float hMask = 1.0 - smoothstep(0.0, max(halfW, 1e-5), rel.x);
        float vMask = antialias(rel.y - halfH, BLUR);
        float focusAlpha = trailColor.a * FOCUS_OPACITY * fade * hMask * vMask;

        outColor = mix(outColor, vec4(trailColor.rgb, outColor.a), focusAlpha);
    }

    // Keep the real cursor crisp on top of either effect.
    fragColor = mix(outColor, baseColor, step(sdfCurrentCursor, 0.0));
}
