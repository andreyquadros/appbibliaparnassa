#!/usr/bin/env node
import fs from 'node:fs/promises';
import path from 'node:path';

const OPENAI_API_KEY = process.env.OPENAI_API_KEY;
const IMAGE_MODEL = process.env.OPENAI_IMAGE_MODEL || 'gpt-image-1';

if (!OPENAI_API_KEY) {
  console.error('OPENAI_API_KEY nao definida.');
  process.exit(1);
}

const root = path.resolve(path.dirname(new URL(import.meta.url).pathname), '..');
const outputDir = path.join(root, 'assets', 'images', 'generated');

const jobs = [
  {
    file: 'splash_book_light.png',
    prompt:
      'Cinematic 3D style digital illustration of an ancient Bible opening with warm golden light rays, volumetric lighting, soft particles, high detail, no text, portrait-friendly composition.',
  },
  {
    file: 'dashboard_parallax_bg.png',
    prompt:
      'Stylized 3D abstract christian dashboard background, layered depth, elegant blue and purple gradient, soft clouds, light beams, minimal and premium, no text.',
  },
  {
    file: 'rewards_scroll_ornament.png',
    prompt:
      '3D ornate sacred scroll with gold ornaments, subtle glow, luxury game reward theme, isolated over rich gradient background, no text, high detail.',
  },
];

async function generateOne(job) {
  const response = await fetch('https://api.openai.com/v1/images/generations', {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${OPENAI_API_KEY}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      model: IMAGE_MODEL,
      prompt: job.prompt,
      size: '1536x1024',
      quality: 'high',
      output_format: 'png',
    }),
  });

  if (!response.ok) {
    const text = await response.text();
    throw new Error(`Erro OpenAI ${response.status}: ${text}`);
  }

  const data = await response.json();
  const b64 = data?.data?.[0]?.b64_json;

  if (!b64) {
    throw new Error(`Resposta sem b64_json para ${job.file}`);
  }

  const buffer = Buffer.from(b64, 'base64');
  await fs.writeFile(path.join(outputDir, job.file), buffer);
  console.log(`Gerado: ${job.file}`);
}

async function main() {
  await fs.mkdir(outputDir, {recursive: true});
  for (const job of jobs) {
    await generateOne(job);
  }
  console.log('Assets finalizados em assets/images/generated');
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
