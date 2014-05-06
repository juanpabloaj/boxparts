module Autoparts
  module Packages
    class Opam < Package
      name 'opam'
      version '1.1.1-20140502'
      description 'OPAM: a source-based package manager for OCaml. With "Real World OCaml" packages preinstalled.'
      source_url 'https://github.com/ocaml/opam/releases/download/1.1.1/opam-full-1.1.1.tar.gz'
      source_sha1 '3d6427679945a0724c8abc15aef9c6a9c1168e42'
      source_filetype 'tar.gz'
      category Category::DEVELOPMENT_TOOLS

      depends_on 'ocaml'
      depends_on 'aspcud'
      def compile
        Dir.chdir(extracted_archive_path + 'opam-full-1.1.1') do

          args = [
            "--prefix=#{prefix_path}",
          ]
          execute './configure', *args
          execute "make"
        end
      end

      def install
        FileUtils.mkdir_p(real_opam_home)
        execute 'ln', '-s', real_opam_home, user_opam_home
        Dir.chdir(extracted_archive_path + 'opam-full-1.1.1') do
          system 'make install'
        end
        ENV['MAKEFLAGS'] = '-j1'
        execute "#{bin_path}/opam init -y -a && eval `#{bin_path}/opam config env` && #{bin_path}/opam install -y async yojson core_extended core_bench cohttp cryptokit menhir utop"
        execute 'rm', user_opam_home
      end

      def user_opam_home
        Path.home + '.opam'
      end
      
      def real_opam_home
        prefix_path + '.opam'
      end
      
      def post_install
        File.write(env_file, env_content)
        unless File.exist?("#{Path.home}/.ocamlinit")
          execute "curl https://gist.githubusercontent.com/avsm/9874360/raw/9290fa85bee7313b7acecc5393c669c522bb6a52/.ocamlinit >> #{Path.home}/.ocamlinit"
        end
        unless File.exist?(user_opam_home)
          execute 'ln', '-s', real_opam_home, user_opam_home
        end
      end

      def env_content
        <<-EOS.unindent
          eval `#{bin_path}/opam config env`
        EOS
      end

      def env_file
        Path.env + name
      end

      def post_uninstall
        user_opam_home.unlink if user_opam_home.symlink?
        env_file.unlink if env_file.exist?
      end
      
      def tips
        <<-EOS.unindent

        Close and open your terminal to have opam working properly after the install, or reload the shell with
          $ . ~/.bash_profile
        EOS
      end
    end
  end
end