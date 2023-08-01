import { GetStaticProps, GetStaticPaths  } from 'next';
import path from 'path';
import { promises as fs } from 'fs'

export const getStaticProps: GetStaticProps = async (context) => {
  return {
    props: {
      params: context.params
    }
  }
}

export const getStaticPaths: GetStaticPaths = async () => {
  const folder = path.join(process.cwd(), '../workouts')
  const filenames = await fs.readdir(folder);

  return {
      paths: filenames.map((s) => ({ params: { slug: s }})),
      fallback: true
  }
}

const Index = (props: any) => {
    console.log(props.params.slug);
    return (
        <div>
            <h1>{props.params.slug}</h1>
        </div>
    )
}
export default Index;