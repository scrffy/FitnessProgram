import { promises as fs } from 'fs';
import Link from 'next/link';
import path from 'path';
import matter, { FrontMatterResult } from 'front-matter';

const Index = ({workouts}: {workouts: FrontMatterResult<any>[]}) => {
  return (
    <main className='p-5'>
      <div className='my-3'>
        <h1 className='font-bold text-2xl'>Workouts</h1>
      </div>
      <div>
        {workouts.map((w, i) => (
          <Link href={`/workouts/${w.attributes.title}`} key={i}>
            <h3>{w.attributes.title}</h3>
          </Link>
        ))}
      </div>
    </main>
  )
}
 
export async function getStaticProps() {
  const folder = path.join(process.cwd(), '../workouts');
  const filenames = await fs.readdir(folder);
  const workouts = filenames.filter(async f => f.endsWith('.md')).map(async f => {
    var content = (await fs.readFile(`../workouts/${f}`)).toString();
    return matter(content);
  });

  return {
    props: {
      workouts: await Promise.all(workouts),
    },
  }
}

export default Index;