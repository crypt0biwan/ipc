import * as Ethers from 'ethers'
import { argv, env, exit } from 'process'
const { INFURA_PROJECT_ID, INFURA_SECRET } = env

import IPCEng from './lib/IPCEng.js'
import IPCLib from './lib/IPCLib.js'

const provider = new Ethers.providers.InfuraProvider('homestead', {
	projectId: INFURA_PROJECT_ID,
	projectSecret: INFURA_SECRET
});

const V0_CONTRACT = '0x4787993750b897fba6aad9e7328fc4f5c126e17c'
const V1_CONTRACT = '0x011c77fa577c500deedad364b8af9e8540b808c0'

import ABI from './abi.json' assert { type: 'json' }
let CONTRACT = null

let tokenId = 0
let msg = 'make sure to call the script with an id, like this: "node get-metadata.js 420"'

try {
    const myArgs = argv.slice(2)

    if(myArgs.length) {
        tokenId = parseInt(myArgs[0], 10)

        if(myArgs[1] != null && myArgs[1] === 'v0') {
            CONTRACT = new Ethers.Contract(V0_CONTRACT, ABI, provider)
        } else {
            CONTRACT = new Ethers.Contract(V1_CONTRACT, ABI, provider)
        }
    } else {
        console.log(msg)
        exit()
    }
} catch(e) {
    console.log(msg)
    exit()
}

const totalSupply = parseInt(await CONTRACT.totalSupply(), 10)

if(tokenId > totalSupply || tokenId === 0) {
    console.log(`Token with id "${tokenId}" doesn't exit (yet). Total supply is ${totalSupply}`)
    exit()
}

const tokenData = await CONTRACT.getIpc(tokenId)
const priceInfo = await CONTRACT.ipcToMarketInfo(tokenId)
const owner = await CONTRACT.ownerOf(tokenId)

const [ name, attributeSeed, dna, experience, timeOfBirth ] = tokenData
const [ sellPrice ] = priceInfo

let details = {
    id: tokenId,
    token_id: tokenId,
    name,
    attribute_seed: attributeSeed,
    dna,
    birth: parseInt(timeOfBirth.toBigInt(), 10),
    xp: parseInt(experience.toBigInt(), 10),
    price: sellPrice,
    gold: 0,
    owner
}

let dna_bytes = IPCLib.ipc_calculate_dna(details.dna)
let attribute_bytes = IPCLib.ipc_calculate_attributes(details.attribute_seed)

details.race = dna_bytes[0]
details.subrace = dna_bytes[1]
details.gender = dna_bytes[2]
details.height = dna_bytes[3]

details.skin_color = dna_bytes[5]
details.hair_color = dna_bytes[6]
details.eye_color = dna_bytes[7]
details.handedness = dna_bytes[4]

details.force = attribute_bytes[0]
details.sustain = attribute_bytes[1]
details.tolerance = attribute_bytes[2]
details.strength = attribute_bytes[0] + attribute_bytes[1] + attribute_bytes[2]

details.speed = attribute_bytes[3]
details.precision = attribute_bytes[4]
details.reaction = attribute_bytes[5]
details.dexterity = attribute_bytes[3] + attribute_bytes[4] + attribute_bytes[5] 

details.memory = attribute_bytes[6]
details.processing = attribute_bytes[7]
details.reasoning = attribute_bytes[8]
details.intelligence = attribute_bytes[6] + attribute_bytes[7] + attribute_bytes[8] 

details.healing = attribute_bytes[9]
details.fortitude = attribute_bytes[10]
details.vitality = attribute_bytes[11]
details.constitution = attribute_bytes[9] + attribute_bytes[10] + attribute_bytes[11] 

details.luck = attribute_bytes[12]

details.accessories = 0,  // not sure how to get this
details.last_updated = details.birth, // not sure how to get this, set it to birth for now
details.meta = { 
    sprite: details.id.toString(), 
    card: details.id, 
    canon: '', 
    rumor: ''
}

let _ipc = IPCLib.ipc_create_ipc_from_json(details)

console.log('###################################')
console.log('####         IPC INFO          ####')
console.log('###################################')
console.log(' ')
console.log(`Total Supply: ${totalSupply}`)
console.log(' ')
console.log(JSON.stringify(IPCLib.ipc_create_label_ipc(_ipc, IPCEng), null, 2))