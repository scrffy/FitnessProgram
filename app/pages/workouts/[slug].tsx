import { GetStaticProps, GetStaticPaths  } from 'next';
import path from 'path';
import { promises as fs } from 'fs';
import Markdown from 'markdown-to-jsx';
import matter from 'front-matter';

export const getStaticProps: GetStaticProps = async (context) => {
  if(context.params) {
    var content = (await fs.readFile(`../workouts/${context.params.slug}.md`)).toString();
    var data = matter(content);

    return {
      props: {
        data
      }
    }
  }
  return {
    props: {
      slug: '',
      content: ''
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
    return (
        <div>
            <h1>{props.data.attributes.title}</h1>
            <Markdown>{props.data.body}</Markdown>
        </div>
    )
}
export default Index;