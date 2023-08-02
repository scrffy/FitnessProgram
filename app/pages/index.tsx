import { promises as fs } from 'fs'
import Link from 'next/link'
import path from 'path'

interface Workout {
  slug: string
}

const Index = ({workouts}: {workouts: Workout[]}) => {
  return (
    <main>
      <div>
        {workouts.map((w, i) => (
          <Link href={`/workouts/${w.slug}`} key={i}>
            <h3>{w.slug}</h3>
          </Link>
        ))}
      </div>
    </main>
  )
}
 
export async function getStaticProps() {
  const folder = path.join(process.cwd(), '../workouts')
  const filenames = await fs.readdir(folder);
  const workouts = filenames.filter(f => f.endsWith('.md')).map((f) => ({
      slug: f.replace('.md', ''),
  }));
  return {
    props: {
      workouts: workouts as Workout[],
    },
  }
}

export default Index;