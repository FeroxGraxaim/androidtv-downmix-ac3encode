package com.stremio.common.players;

import dev.jdtech.mpv.MPVLib;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.Locale;
import org.json.JSONObject;

/**
 * MPV virtual audio rows: Dialogue downmix (lavfi) and AC3 encode (lavcac3enc).
 * Synthetic IDs map back to the real aid. clear() resets mode on each new file.
 */
public final class MpvDownmixTracks {

    public static final String PREFIX_DOWNMIX = "downmix:";
    public static final String PREFIX_AC3 = "ac3enc:";

    public static final String LABEL_DOWNMIX = "Dialogue downmix";
    public static final String LABEL_AC3 = "AC3 5.1 encode";

    public static final String FILTER_DOWNMIX =
            "lavfi=[pan=stereo|"
                    + "FL=0.50*FL+0.85*FC+0.20*LFE+0.35*BL+0.35*SL|"
                    + "FR=0.50*FR+0.85*FC+0.20*LFE+0.35*BR+0.35*SR,"
                    + "acompressor=threshold=0.125:ratio=3:attack=20:release=250:makeup=1.5,"
                    + "alimiter=limit=0.95:level=0]";

    public static final String FILTER_AC3 =
            "lavcac3enc=tospdif=yes:bitrate=640:minch=3";

    /** null = original; PREFIX_DOWNMIX / PREFIX_AC3 = virtual ativa */
    private static volatile String mode;
    private static volatile String lastTrackList;

    private MpvDownmixTracks() {}

    public static void rememberTrackList(String json) {
        if (json != null && json.length() > 0) {
            lastTrackList = json;
        }
    }

    /** Compat: qualquer virtual ativa. */
    public static boolean isEnabled() {
        return mode != null;
    }

    public static void setEnabled(boolean value) {
        if (!value) {
            mode = null;
        }
    }

    /** Reset sticky mode when a new file is loaded. Never the default. */
    public static void clear(MPVLib mpv) {
        mode = null;
        if (mpv == null) {
            return;
        }
        mpv.setPropertyString("af", "");
        mpv.setPropertyString("audio-channels", "auto-safe");
    }

    public static boolean isVirtual(String id) {
        return id != null
                && (id.startsWith(PREFIX_DOWNMIX) || id.startsWith(PREFIX_AC3));
    }

    public static boolean isDownmix(String id) {
        return id != null && id.startsWith(PREFIX_DOWNMIX);
    }

    public static boolean isAc3(String id) {
        return id != null && id.startsWith(PREFIX_AC3);
    }

    public static String sourceId(String id) {
        if (isDownmix(id)) {
            return id.substring(PREFIX_DOWNMIX.length());
        }
        if (isAc3(id)) {
            return id.substring(PREFIX_AC3.length());
        }
        return id;
    }

    public static List<Track> expand(Track source, JSONObject json) {
        if (source == null) {
            return Collections.emptyList();
        }
        if (source.getType() != TrackType.AUDIO || !isMultichannel(source, json)) {
            return Collections.singletonList(source);
        }
        boolean mpvSelected = source.getSelected();
        boolean downmixOn = PREFIX_DOWNMIX.equals(mode);
        boolean ac3On = PREFIX_AC3.equals(mode);

        ArrayList<Track> out = new ArrayList<Track>(3);
        out.add(copySelected(source, mpvSelected && mode == null));
        out.add(virtualTrack(source, PREFIX_DOWNMIX, LABEL_DOWNMIX, mpvSelected && downmixOn));
        out.add(virtualTrack(source, PREFIX_AC3, LABEL_AC3, mpvSelected && ac3On));
        return out;
    }

    public static String apply(MPVLib mpv, Track track) {
        if (mpv == null || track == null) {
            return lastTrackList;
        }
        String id = track.getId();
        String source = sourceId(id);

        if (isDownmix(id)) {
            mode = PREFIX_DOWNMIX;
        } else if (isAc3(id)) {
            mode = PREFIX_AC3;
        } else {
            mode = null;
        }

        try {
            mpv.setPropertyInt("aid", Integer.parseInt(source));
        } catch (NumberFormatException ignored) {
            mpv.setPropertyString("aid", source);
        }

        if (isDownmix(id)) {
            mpv.setPropertyString("ad-lavc-downmix", "no");
            mpv.setPropertyString("audio-channels", "stereo");
            mpv.setPropertyString("af", FILTER_DOWNMIX);
        } else if (isAc3(id)) {
            mpv.setPropertyString("ad-lavc-downmix", "no");
            // manter multicanal para o encoder AC3
            mpv.setPropertyString("audio-channels", "auto");
            mpv.setPropertyString("af", FILTER_AC3);
        } else {
            mpv.setPropertyString("af", "");
            mpv.setPropertyString("audio-channels", "auto-safe");
        }

        String json = mpv.getPropertyString("track-list");
        if (json == null || json.length() == 0) {
            json = lastTrackList;
        }
        return json;
    }

    static boolean isMultichannel(Track source, JSONObject json) {
        int channels = channelCount(json);
        if (channels > 2) {
            return true;
        }
        if (channels > 0) {
            return false;
        }
        String codec = source.getCodec();
        if (codec == null) {
            return false;
        }
        String lower = codec.toLowerCase(Locale.ROOT);
        return lower.indexOf("dts") >= 0
                || lower.indexOf("truehd") >= 0
                || lower.indexOf("eac3") >= 0
                || lower.indexOf("atmos") >= 0
                || lower.indexOf("aac") >= 0;
    }

    static int channelCount(JSONObject json) {
        if (json == null || json.isNull("audio-channels")) {
            return 0;
        }
        int value = json.optInt("audio-channels", 0);
        if (value > 0) {
            return value;
        }
        String raw = json.optString("audio-channels", "");
        if (raw.length() == 0) {
            return 0;
        }
        try {
            return Integer.parseInt(raw.trim());
        } catch (NumberFormatException ignored) {
            if (raw.startsWith("7.1")) {
                return 8;
            }
            if (raw.startsWith("5.1") || raw.startsWith("6.1")) {
                return 6;
            }
            return 0;
        }
    }

    static String virtualLabel(Track source, String label) {
        String src = source.getLabel();
        if (src == null || src.length() == 0) {
            return label;
        }
        return src + " (" + label + ")";
    }

    static Track virtualTrack(Track source, String prefix, String label, boolean selected) {
        return new Track(
                source.getType(),
                prefix + source.getId(),
                source.getUri(),
                virtualLabel(source, label),
                source.getLanguage(),
                source.getEmbedded(),
                source.getCommentary(),
                source.getForced(),
                source.getCodec(),
                source.getMime(),
                source.getFourcc(),
                selected);
    }

    static Track copySelected(Track source, boolean selected) {
        if (source.getSelected() == selected) {
            return source;
        }
        return new Track(
                source.getType(),
                source.getId(),
                source.getUri(),
                source.getLabel(),
                source.getLanguage(),
                source.getEmbedded(),
                source.getCommentary(),
                source.getForced(),
                source.getCodec(),
                source.getMime(),
                source.getFourcc(),
                selected);
    }
}
