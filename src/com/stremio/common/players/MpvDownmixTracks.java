package com.stremio.common.players;

import dev.jdtech.mpv.MPVLib;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.Locale;
import org.json.JSONObject;

/**
 * MPV virtual "Dialogue downmix" rows plus lavfi pan/compressor toggle.
 * Matches stremio-android / stremio-shell: synthetic ID maps back to the real aid.
 *
 * PlaybackManager sorts audio by commentary, embedded, then label. The virtual
 * label is derived from the source so the row always sorts immediately below it.
 * {@link #clear} resets the sticky toggle on each new file so downmix is never default.
 */
public final class MpvDownmixTracks {
    public static final String PREFIX = "downmix:";
    public static final String LABEL = "Dialogue downmix";
    public static final String FILTER =
            "lavfi=[pan=stereo|"
                    + "FL=0.50*FL+0.85*FC+0.20*LFE+0.35*BL+0.35*SL|"
                    + "FR=0.50*FR+0.85*FC+0.20*LFE+0.35*BR+0.35*SR,"
                    + "acompressor=threshold=0.125:ratio=3:attack=20:release=250:makeup=1.5,"
                    + "alimiter=limit=0.95:level=0]";

    private static volatile boolean enabled;
    private static volatile String lastTrackList;

    private MpvDownmixTracks() {}

    public static void rememberTrackList(String json) {
        if (json != null && json.length() > 0) {
            lastTrackList = json;
        }
    }

    public static boolean isEnabled() {
        return enabled;
    }

    public static void setEnabled(boolean value) {
        enabled = value;
    }

    /** Reset sticky downmix when a new file is loaded. Never the default. */
    public static void clear(MPVLib mpv) {
        enabled = false;
        if (mpv == null) {
            return;
        }
        mpv.setPropertyString("af", "");
        mpv.setPropertyString("audio-channels", "auto-safe");
    }

    public static boolean isVirtual(String id) {
        return id != null && id.startsWith(PREFIX);
    }

    public static String sourceId(String id) {
        if (isVirtual(id)) {
            return id.substring(PREFIX.length());
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
        boolean downmix = isEnabled();
        ArrayList<Track> out = new ArrayList<Track>(2);
        out.add(copySelected(source, mpvSelected && !downmix));
        out.add(virtualTrack(source, mpvSelected && downmix));
        return out;
    }

    public static String apply(MPVLib mpv, Track track) {
        if (mpv == null || track == null) {
            return lastTrackList;
        }
        String id = track.getId();
        boolean virtual = isVirtual(id);
        setEnabled(virtual);
        String source = sourceId(id);
        try {
            mpv.setPropertyInt("aid", Integer.parseInt(source));
        } catch (NumberFormatException ignored) {
            mpv.setPropertyString("aid", source);
        }
        if (virtual) {
            mpv.setPropertyString("ad-lavc-downmix", "no");
            mpv.setPropertyString("audio-channels", "stereo");
            mpv.setPropertyString("af", FILTER);
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
                || lower.indexOf("atmos") >= 0;
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

    /**
     * PlaybackManager sorts audio by label. Prefix with the source title so
     * this sibling sits immediately below the original. Untitled sources keep
     * "Dialogue downmix", which still sorts after a null original label.
     */
    static String virtualLabel(Track source) {
        String src = source.getLabel();
        if (src == null || src.length() == 0) {
            return LABEL;
        }
        return src + " (" + LABEL + ")";
    }

    static Track virtualTrack(Track source, boolean selected) {
        return new Track(
                source.getType(),
                PREFIX + source.getId(),
                source.getUri(),
                virtualLabel(source),
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
