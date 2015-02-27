#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include <stdio.h>
#include <fcntl.h>
#include <unistd.h>
#include <sys/stat.h>
#include "mbelib.h"

typedef struct
{
  unsigned char *mbe_in_data;
  unsigned int mbe_in_pos, mbe_in_size;
  unsigned char is_imbe;
  float audio_out_temp_buf[960];
  int errs;
  int errs2;
  char err_str[64];
  mbe_parms cur_mp;
  mbe_parms prev_mp;
  mbe_parms prev_mp_enhanced;
  float aout_gain;
  float aout_max_buf[33];
  unsigned int aout_max_buf_idx;
} mbedecode_state;

static int readAmbe2450Data (mbedecode_state *state, char *ambe_d)
{
  int i, j, k;
  unsigned char b;

  state->errs2 = state->mbe_in_data[state->mbe_in_pos++];
  state->errs = state->errs2;

  k = 0;
  for (i = 0; i < 6; i++) {
      b = state->mbe_in_data[state->mbe_in_pos++];
      if (state->mbe_in_pos >= state->mbe_in_size) {
          return (1);
      }
      for (j = 0; j < 8; j++) {
          ambe_d[k] = (b & 128) >> 7;
          b = b << 1;
          b = b & 255;
          k++;
      }
  }
  b = state->mbe_in_data[state->mbe_in_pos++];
  ambe_d[48] = (b & 1);

  return (0);
}

static int readImbe4400Data (mbedecode_state *state, char *imbe_d)
{
  int i, j, k;
  unsigned char b;

  state->errs2 = state->mbe_in_data[state->mbe_in_pos++];
  state->errs = state->errs2;

  k = 0;
  for (i = 0; i < 11; i++) {
      b = state->mbe_in_data[state->mbe_in_pos++];
      if (state->mbe_in_pos >= state->mbe_in_size) {
          return (1);
      }
      for (j = 0; j < 8; j++) {
          imbe_d[k] = (b & 128) >> 7;
          b = b << 1;
          b = b & 255;
          k++;
      }
  }
  return (0);
}

static void ProcessAGC(mbedecode_state *state)
{
  int i, n;
  float aout_abs, max, gainfactor, gaindelta, maxbuf;

  // detect max level
  max = 0;
  for (n = 0; n < 160; n++) {
      aout_abs = fabsf (state->audio_out_temp_buf[n]);
      if (aout_abs > max)
          max = aout_abs;
  }
  state->aout_max_buf[state->aout_max_buf_idx++] = max;
  if (state->aout_max_buf_idx > 24) {
      state->aout_max_buf_idx = 0;
  }

  // lookup max history
  for (i = 0; i < 25; i++) {
      maxbuf = state->aout_max_buf[i];
      if (maxbuf > max)
          max = maxbuf;
  }

  // determine optimal gain level
  if (max > 0.0f) {
      //gainfactor = (30000.0f / max);
      gainfactor = (32767.0f / max);
  } else {
      gainfactor = 50.0f;
  }
  if (gainfactor < state->aout_gain) {
      state->aout_gain = gainfactor;
      gaindelta = 0.0f;
  } else {
      if (gainfactor > 50.0f) {
          gainfactor = 50.0f;
      }
      gaindelta = gainfactor - state->aout_gain;
      if (gaindelta > (0.05f * state->aout_gain)) {
          gaindelta = (0.05f * state->aout_gain);
      }
  }

  // adjust output gain
  state->aout_gain += gaindelta;
}

static void writeSynthesizedVoice (int wav_out_fd, mbedecode_state *state)
{
  short aout_buf[160];
  unsigned int n;

  ProcessAGC(state);
  for (n = 0; n < 160; n++) {
    float tmp = state->audio_out_temp_buf[n];
    tmp *= state->aout_gain;

    if (tmp > 32767.0f) {
        tmp = 32767.0f;
    } else if (tmp < -32767.0f) {
        tmp = -32767.0f;
    }
    aout_buf[n] = lrintf(tmp);
  }

  write(wav_out_fd, aout_buf, 160 * sizeof(int16_t));
}

typedef struct _WAVHeader {
    uint32_t riff;
    uint32_t totalsize;
    uint32_t pad0;
    uint32_t hdr_chunkname;
    uint32_t hdr_chunklen;
    uint16_t wav_id;
    uint16_t channels;
    uint32_t samplerate;
    uint32_t bitrate;
    uint32_t block_align;
    uint32_t data_chunkname;
    uint32_t data_chunksize;
} __attribute__((packed)) WAVHeader;

static void write_wav_header(int fd, uint32_t rate, uint32_t nsamples)
{
    WAVHeader w;

    w.riff = 0x46464952;
    w.totalsize = nsamples + 24;
    w.pad0 = 0x45564157;
    w.hdr_chunkname = 0x20746D66; /* "fmt " */
    w.hdr_chunklen = 0x10;
    w.wav_id = 1;
    w.channels = 1;
    w.samplerate = rate;
    w.bitrate = rate*2;
    w.block_align = 0x00100010;
    w.data_chunkname = 0x61746164;
    w.data_chunksize = nsamples;
    write(fd, &w, sizeof(WAVHeader));
}

static void usage(void) {
    const char *usage_str = "decode_ambe: a standalone MBE decoder for the AMBE3600x2450 and IMBE7200x4400 formats.\n"
                            "Usage: decode_mbe [AMB/IMB file] [Output Wavfile] <uvquality>\n"
                            "Where [AMB/IMBE file] is an AMBE (or IMBE) file as output by, for instance, DSD's -d option,\n"
                            "and [Output Wavfile] will be the decoded output, in signed 16-bit PCM, at 8kHz samplerate.\n"
                            "Takes an optional third argument that is the speech synthesis quality in terms of the number of waves per band.\n"
                            "Valid values lie in the closed interval [1, 64], with the default being 3.\n";
    write(1, usage_str, strlen(usage_str));
}

int main(int argc, char **argv) {
    mbedecode_state state;
    struct stat st;
    int mbe_in_fd = -1;
    char cookie[5];
    char ambe_d[49];
    char imbe_d[88];
    unsigned int nsamples = 0;
    unsigned int uvquality = 3;
    int out_fd = -1;
    memset(&state, 0, sizeof(mbedecode_state));

    if (argc < 3) {
        usage();
        return -1;
    }

    if (argc > 3) {
        uvquality = strtoul(argv[3], NULL, 10);
    }

    mbe_in_fd = open (argv[1], O_RDONLY);
    if (mbe_in_fd < 0) {
      printf ("Error: could not open %s\n", argv[1]);
      return -1;
    }
    fstat(mbe_in_fd, &st);
    state.mbe_in_pos = 4;
    state.mbe_in_size = st.st_size;
    state.mbe_in_data = malloc(st.st_size+1);
    read(mbe_in_fd, state.mbe_in_data, state.mbe_in_size);
    close(mbe_in_fd);

    memcpy(cookie, state.mbe_in_data, 4);
    if (!memcmp(cookie, ".amb", 4)) {
      state.is_imbe = 0;
    } else if (!memcmp(cookie, ".imb", 4)) {
      state.is_imbe = 1;
    } else {
      printf ("Error - unrecognized file type\n");
      return -1;
    }

    state.aout_gain = 25;
    mbe_initMbeParms (&state.cur_mp, &state.prev_mp, &state.prev_mp_enhanced);

    /* how many frames there are:
     * AMBE: nbytes - 4 (header) / 8 (AMBE bytes per 160-sample frame)
     * IMBE: nbytes - 4 (header) / 12 (AMBE bytes per 160-sample frame)
     * Multiply by 160 to get samples.
     * For simplicity we factor out a common factor of 4.
     */
    nsamples = (40 * (state.mbe_in_size - 4));
    if (state.is_imbe) {
        nsamples /= 3;
    } else {
        nsamples >>= 1;
    }

    out_fd = open(argv[2], O_WRONLY | O_CREAT, 0644);
    write_wav_header(out_fd, 8000, nsamples);

    printf ("Playing %s\n", argv[1]);
    while (state.mbe_in_pos < state.mbe_in_size) {
        int errs = 0;
        char *err_str = state.err_str;
        if (state.is_imbe) {
          readImbe4400Data (&state, imbe_d);
          mbe_processImbe4400Dataf (state.audio_out_temp_buf, &errs, &state.errs2, err_str, imbe_d,
                                    &state.cur_mp, &state.prev_mp, &state.prev_mp_enhanced, uvquality);
        } else {
          readAmbe2450Data (&state, ambe_d);
          mbe_processAmbe2450Dataf (state.audio_out_temp_buf, &errs, &state.errs2, err_str, ambe_d,
                                    &state.cur_mp, &state.prev_mp, &state.prev_mp_enhanced, uvquality);
        }
        if (state.errs2 > 0) {
            printf("decodeAmbe2450Parms: errs2: %u, err_str: %s\n", state.errs2, state.err_str);
        }
        writeSynthesizedVoice (out_fd, &state);
    }
    close(out_fd);
    return 0;
}

