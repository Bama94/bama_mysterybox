fx_version 'cerulean'
game 'gta5'

author 'Bama94'
description 'Mystery Box - Call of Duty Zombies Style'
version '1.0.0'

lua54 'yes'
use_experimental_fxv2_oal 'yes'

shared_scripts {
    '@ox_lib/init.lua',
    '@qbx_core/modules/lib.lua',
    'config/*.lua'
}

client_scripts {
    'client/*.lua'
}

server_scripts {
    'server/*.lua'
}

files {
    'locales/*.json',
    'config/*.lua',
    'data/mysterybox_sounds.dat54.rel',
    'audiodirectory/mysterybox_sounds.awc'
}

data_file 'AUDIO_WAVEPACK' 'audiodirectory'
data_file 'AUDIO_SOUNDDATA' 'data/mysterybox_sounds.dat'

dependencies {
    'ox_target',
    'ox_lib',
    'qbx_core',
}
