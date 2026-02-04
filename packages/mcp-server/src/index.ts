#!/usr/bin/env node

import { Server } from '@modelcontextprotocol/sdk/server/index.js';
import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio.js';
import {
  CallToolRequestSchema,
  ListToolsRequestSchema,
  Tool,
} from '@modelcontextprotocol/sdk/types.js';
import fetch from 'node-fetch';
import { spawn } from 'child_process';
import { writeFileSync, unlinkSync, existsSync } from 'fs';
import { tmpdir } from 'os';
import { join } from 'path';
import { platform } from 'os';

// Configuration
const ELEVENLABS_API_KEY = process.env.ELEVENLABS_API_KEY;
const ELEVENLABS_VOICE_ID = process.env.ELEVENLABS_VOICE_ID || '21m00Tcm4TlvDq8ikWAM'; // Rachel
const ELEVENLABS_MODEL = process.env.ELEVENLABS_MODEL || 'eleven_flash_v2_5';
const API_BASE = 'https://api.elevenlabs.io/v1';

// Validate API key at startup
if (!ELEVENLABS_API_KEY) {
  console.error('Error: ELEVENLABS_API_KEY environment variable not set');
  console.error('Setup: op read "op://Private/ElevenLabs/API_KEY"');
  process.exit(1);
}

// Audio player detection (cross-platform)
function getAudioPlayer(): string | null {
  const os = platform();
  if (os === 'darwin') {
    return 'afplay'; // macOS
  } else if (os === 'linux') {
    // Check for available players on Linux
    const players = ['mpv', 'ffplay', 'aplay'];
    for (const player of players) {
      try {
        const which = spawn('which', [player]);
        let found = false;
        which.on('close', (code) => {
          if (code === 0) found = true;
        });
        if (found) return player;
      } catch {
        continue;
      }
    }
  }
  return null;
}

const AUDIO_PLAYER = getAudioPlayer();

// Play audio file
async function playAudio(filePath: string): Promise<void> {
  if (!AUDIO_PLAYER) {
    throw new Error('No audio player found. Install mpv or ffplay.');
  }

  return new Promise((resolve, reject) => {
    const player = spawn(AUDIO_PLAYER, [filePath]);
    player.on('close', (code) => {
      if (code === 0) {
        resolve();
      } else {
        reject(new Error(`Audio player exited with code ${code}`));
      }
    });
    player.on('error', (err) => reject(err));
  });
}

// Text-to-Speech API call
async function textToSpeech(
  text: string,
  voiceId: string = ELEVENLABS_VOICE_ID,
  modelId: string = ELEVENLABS_MODEL
): Promise<Buffer> {
  const url = `${API_BASE}/text-to-speech/${voiceId}`;

  const response = await fetch(url, {
    method: 'POST',
    headers: {
      'xi-api-key': ELEVENLABS_API_KEY!,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      text,
      model_id: modelId,
    }),
  });

  if (!response.ok) {
    const errorText = await response.text();
    throw new Error(`ElevenLabs API error: ${response.status} ${errorText}`);
  }

  return Buffer.from(await response.arrayBuffer());
}

// List available voices
async function listVoices(): Promise<any> {
  const url = `${API_BASE}/voices`;

  const response = await fetch(url, {
    method: 'GET',
    headers: {
      'xi-api-key': ELEVENLABS_API_KEY!,
    },
  });

  if (!response.ok) {
    throw new Error(`ElevenLabs API error: ${response.status}`);
  }

  return await response.json();
}

// Get voice info
async function getVoiceInfo(voiceId: string): Promise<any> {
  const url = `${API_BASE}/voices/${voiceId}`;

  const response = await fetch(url, {
    method: 'GET',
    headers: {
      'xi-api-key': ELEVENLABS_API_KEY!,
    },
  });

  if (!response.ok) {
    throw new Error(`ElevenLabs API error: ${response.status}`);
  }

  return await response.json();
}

// Define MCP tools
const tools: Tool[] = [
  {
    name: 'text_to_speech',
    description: 'Convert text to speech using ElevenLabs API. Generates audio and optionally plays it.',
    inputSchema: {
      type: 'object',
      properties: {
        text: {
          type: 'string',
          description: 'The text to convert to speech',
        },
        voice_id: {
          type: 'string',
          description: 'Voice ID (default: Rachel - 21m00Tcm4TlvDq8ikWAM)',
        },
        model_id: {
          type: 'string',
          description: 'Model ID (default: eleven_flash_v2_5)',
        },
        play: {
          type: 'boolean',
          description: 'Whether to play the audio after generation (default: true)',
        },
        save_path: {
          type: 'string',
          description: 'Optional path to save the audio file',
        },
      },
      required: ['text'],
    },
  },
  {
    name: 'list_voices',
    description: 'List all available voices from ElevenLabs',
    inputSchema: {
      type: 'object',
      properties: {},
    },
  },
  {
    name: 'get_voice_info',
    description: 'Get detailed information about a specific voice',
    inputSchema: {
      type: 'object',
      properties: {
        voice_id: {
          type: 'string',
          description: 'The ID of the voice to query',
        },
      },
      required: ['voice_id'],
    },
  },
];

// Create MCP server
const server = new Server(
  {
    name: 'elevenlabs-tts',
    version: '0.1.0',
  },
  {
    capabilities: {
      tools: {},
    },
  }
);

// Handle tool list requests
server.setRequestHandler(ListToolsRequestSchema, async () => {
  return { tools };
});

// Handle tool execution
server.setRequestHandler(CallToolRequestSchema, async (request) => {
  const { name, arguments: args } = request.params;

  if (!args) {
    throw new Error('Arguments are required');
  }

  try {
    switch (name) {
      case 'text_to_speech': {
        const text = args.text as string;
        const voiceId = (args.voice_id as string) || ELEVENLABS_VOICE_ID;
        const modelId = (args.model_id as string) || ELEVENLABS_MODEL;
        const play = args.play !== false; // Default true
        const savePath = args.save_path as string | undefined;

        // Generate audio
        const audioBuffer = await textToSpeech(text, voiceId, modelId);

        // Save to temp file or specified path
        const outputPath = savePath || join(tmpdir(), `elevenlabs-${Date.now()}.mp3`);
        writeFileSync(outputPath, audioBuffer);

        let result = `Audio generated: ${outputPath}`;

        // Play if requested
        if (play && AUDIO_PLAYER) {
          await playAudio(outputPath);
          result += ` (played with ${AUDIO_PLAYER})`;

          // Clean up temp file after playing
          if (!savePath) {
            unlinkSync(outputPath);
          }
        }

        return {
          content: [{ type: 'text', text: result }],
        };
      }

      case 'list_voices': {
        const voices = await listVoices();
        const formatted = voices.voices
          .map((v: any) => `${v.name} (${v.voice_id}) - ${v.category}`)
          .join('\n');

        return {
          content: [
            {
              type: 'text',
              text: `Available voices:\n\n${formatted}\n\nDefault: Rachel (${ELEVENLABS_VOICE_ID})`,
            },
          ],
        };
      }

      case 'get_voice_info': {
        const voiceId = args.voice_id as string;
        const info = await getVoiceInfo(voiceId);

        return {
          content: [
            {
              type: 'text',
              text: JSON.stringify(info, null, 2),
            },
          ],
        };
      }

      default:
        throw new Error(`Unknown tool: ${name}`);
    }
  } catch (error) {
    const errorMessage = error instanceof Error ? error.message : String(error);
    return {
      content: [{ type: 'text', text: `Error: ${errorMessage}` }],
      isError: true,
    };
  }
});

// Start server
async function main() {
  const transport = new StdioServerTransport();
  await server.connect(transport);
  console.error('ElevenLabs MCP server running on stdio');
}

main().catch((error) => {
  console.error('Server error:', error);
  process.exit(1);
});
