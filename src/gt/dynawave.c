#include <zlib.h>
#include "dynawave.h"
#include "gametank.h"
#include "banking.h"

char pitch_table[216] = {
    0x00, 0x4D, 0x00, 0x51, 0x00, 0x56, 0x00, 0x5B, 0x00, 0x61, 0x00, 0x66, 0x00, 0x6C, 0x00, 0x73, 0x00, 0x7A, 0x00, 0x81, 0x00, 0x89, 0x00, 0x91,
    0x00, 0x99, 0x00, 0xA2, 0x00, 0xAC, 0x00, 0xB6, 0x00, 0xC1, 0x00, 0xCD, 0x00, 0xD9, 0x00, 0xE6, 0x00, 0xF3, 0x01, 0x02, 0x01, 0x11, 0x01, 0x21,
    0x01, 0x33, 0x01, 0x45, 0x01, 0x58, 0x01, 0x6D, 0x01, 0x82, 0x01, 0x99, 0x01, 0xB2, 0x01, 0xCB, 0x01, 0xE7, 0x02, 0x04, 0x02, 0x22, 0x02, 0x43,
    0x02, 0x65, 0x02, 0x8A, 0x02, 0xB0, 0x02, 0xD9, 0x03, 0x04, 0x03, 0x32, 0x03, 0x63, 0x03, 0x97, 0x03, 0xCD, 0x04, 0x07, 0x04, 0x44, 0x04, 0x85,
    0x04, 0xCA, 0x05, 0x13, 0x05, 0x60, 0x05, 0xB2, 0x06, 0x09, 0x06, 0x65, 0x06, 0xC6, 0x07, 0x2D, 0x07, 0x9A, 0x08, 0x0E, 0x08, 0x89, 0x09, 0x0B,
    0x09, 0x94, 0x0A, 0x26, 0x0A, 0xC1, 0x0B, 0x64, 0x0C, 0x12, 0x0C, 0xCA, 0x0D, 0x8C, 0x0E, 0x5B, 0x0F, 0x35, 0x10, 0x1D, 0x11, 0x12, 0x12, 0x16,
    0x13, 0x29, 0x14, 0x4D, 0x15, 0x82, 0x16, 0xC9, 0x18, 0x24, 0x19, 0x93, 0x1B, 0x19, 0x1C, 0xB5, 0x1E, 0x6A, 0x20, 0x39, 0x22, 0x24, 0x24, 0x2B,
    0x26, 0x52, 0x28, 0x99, 0x2B, 0x03, 0x2D, 0x92, 0x30, 0x48, 0x33, 0x27, 0x36, 0x31, 0x39, 0x6A, 0x3C, 0xD4, 0x40, 0x72, 0x44, 0x47, 0x48, 0x57,
    0x4C, 0xA4, 0x51, 0x32, 0x56, 0x06, 0x5B, 0x24, 0x60, 0x8F, 0x66, 0x4D, 0x6C, 0x62, 0x72, 0xD4, 0x79, 0xA8, 0x80, 0xE4, 0x88, 0x8E, 0x90, 0xAD};

extern const unsigned char* DynaWave;

char audio_params_index = 0;
char *wavetable_page;

void wait();

void init_dynawave()
{
    *audio_rate = 0x7F;

    change_rom_bank(0);
    inflatemem(aram, &DynaWave);

    audio_params_index = 0;
    AUDIO_PARAM_INPUT_BUFFER[0] = 0;
    *audio_rate = 255;
    *audio_reset = 0;
    while(*WAVE_TABLE_LOCATION == 0) {
        
    }
    wavetable_page = 0x3000;
    wavetable_page += *WAVE_TABLE_LOCATION;
}

void push_audio_param(char param, char value) {
    AUDIO_PARAM_INPUT_BUFFER[audio_params_index++] = param;
    AUDIO_PARAM_INPUT_BUFFER[audio_params_index++] = value;
}

void flush_audio_params() {
    AUDIO_PARAM_INPUT_BUFFER[audio_params_index] = 0;
    *audio_nmi = 1;
    audio_params_index = 0;
}

void set_note(char ch, char n) {
    push_audio_param(PITCH_MSB + ch, pitch_table[ n * 2]);
    push_audio_param(PITCH_LSB + ch, pitch_table[ n * 2 + 1]);
}