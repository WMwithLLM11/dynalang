FROM nvidia/cuda:11.8.0-base-ubuntu22.04

LABEL maintainer="ssone"

RUN ln -sf /usr/share/zoneinfo/Asia/Tokyo /etc/localtime

# User Settings & Installation of Required Packages
USER root

RUN apt update && \
    apt install -y bash python3 python3-pip && \
    apt install -y libglew-dev ca-certificates zip unzip bzip2 lsof less nkf swig && \
    apt install -y x11-xserver-utils xvfb pkg-config libsdl2-2.0-0 libsdl2-dev && \
    apt install -y libgtk-3-dev libgstreamer-gl1.0-0 && \
    apt install -y libhdf5-dev libfreetype6-dev && \
    apt install -y libsdl1.2-dev libsdl-image1.2-dev libsdl-ttf2.0-dev && \
    apt install -y libsdl-mixer1.2-dev libportmidi-dev libx264-dev

RUN apt install -y sudo curl wget ssh vim emacs git gcc g++ make cmake && \
    apt install -y tesseract-ocr espeak-ng ca-certificates bzip2 zip && \
    apt install -y tree htop bmon iotop build-essential openjdk-8-jdk-headless gfortran && \
    apt install -y build-essential x11-apps && \
    apt install -y emacs nkf graphviz graphviz-dev && \
    apt install -y language-pack-ja-base language-pack-ja && \
    apt install -y mecab libmecab-dev mecab-ipadic-utf8 && \
    apt clean && rm -rf /var/lib/apt/lists/*

##################
# Neologd
#RUN git clone --depth 1 https://github.com/neologd/mecab-ipadic-neologd.git ; exit 0
#RUN cd mecab-ipadic-neologd && \
#  ./bin/install-mecab-ipadic-neologd -n -y && \
#    echo "dicdir=/usr/lib/x86_64-linux-gnu/mecab/dic/mecab-ipadic-neologd">/etc/mecabrc


##########################################################################################
# root password
RUN echo 'root:ageha' | chpasswd


# Create a user named "ssone" and set up the home directory.
ARG USERNAME=ssone
ARG USER_UID=1000
ARG USER_GID=$USER_UID

# ユーザーとグループを作成し、sudoをインストール
RUN groupadd --gid $USER_GID $USERNAME \
    && useradd --uid $USER_UID --gid $USER_GID -m $USERNAME \
    && apt-get update \
    && apt-get install -y sudo \
    && echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME

# Minicondaのインストール
USER $USERNAME
WORKDIR /home/$USERNAME
RUN curl -LO https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh \
    && bash Miniconda3-latest-Linux-x86_64.sh -b \
    && rm Miniconda3-latest-Linux-x86_64.sh

# PATHの設定
ENV PATH /home/$USERNAME/miniconda3/bin:$PATH

# Python-related setupls
COPY requirements.txt .

# Add conda configuration to .bashrc
RUN echo 'export PATH="$HOME/miniconda3/bin:$PATH"' >> ~/.bashrc && \
    echo 'export LD_PRELOAD="/usr/lib/x86_64-linux-gnu/libstdc++.so.6"' >> ~/.bashrc && \
    echo 'source activate base' >> ~/.bashrc

# Install Jupyter notebook
RUN $HOME/miniconda3/bin/conda install -c conda-forge jupyter -y

# Conda環境の作成と設定
RUN conda create -n wm2024_win -y python=3.9 \
    && conda install -n wm2024_win ipykernel \
    && /home/$USERNAME/miniconda3/envs/wm2024_win/bin/python -m ipykernel install --user --name wm2024_win --display-name "Python (wm2024_win)" \
    && /home/$USERNAME/miniconda3/envs/wm2024_win/bin/python -m pip install -r requirements.txt \
    # torch 2.1.* on CUDA 11.8, python3.9
    && conda install -n wm2024_win pytorch torchvision torchaudio pytorch-cuda=11.8 -c pytorch -c nvidia \
    # tensorflow on CUDA 11.8, python3.9
    && /home/$USERNAME/miniconda3/envs/wm2024_win/bin/python -m pip install tensorflow[and-cuda] \
    # Need typing-extension > 4.5.0 in pytorch and tensorflow-probability but tensorflow==2.5.0 can't use typing-extension=4.5
    && /home/$USERNAME/miniconda3/envs/wm2024_win/bin/python -m pip install tensorflow-probability \
    # Notice if your gpu is cuda11 then
    && /home/$USERNAME/miniconda3/envs/wm2024_win/bin/python -m pip install jax[cuda11_pip] -f https://storage.googleapis.com/jax-releases/jax_cuda_releases.html \
    # torch geometric with python3.9, pytorch 2.1.* and CUDA 11.8
    && /home/$USERNAME/miniconda3/envs/wm2024_win/bin/python -m pip install torch_geometric \
    && /home/$USERNAME/miniconda3/envs/wm2024_win/bin/python -m pip install pyg_lib torch_scatter torch_sparse torch_cluster torch_spline_conv -f https://data.pyg.org/whl/torch-2.1.0+cu118.html \
    && conda remove -n wm2024_win ffmpeg -y
    # && /home/$USERNAME/miniconda3/envs/wm2024_win/bin/python -m pip install homegrid
##########
# Add to Jupyter's path
RUN echo 'export PATH=$PATH:/home/$USERNAME/.local/bin' >> ~/.bashrc

# Setting Jupyter Notebook (Allow access Without password)
RUN mkdir -p /home/$USERNAME/.jupyter && \
    echo "c.NotebookApp.token = ''\nc.NotebookApp.password = ''" > /home/$USERNAME/.jupyter/jupyter_notebook_config.py


########################################################################################
USER root

RUN apt update && \
    apt install -y ffmpeg

# Open SSH Port
RUN mkdir /var/run/sshd
EXPOSE 22

# Open Jupyter Notebook Port
EXPOSE 8888

# Setting Env
ENV DISPLAY host.docker.internal:0.0

USER $USERNAME
WORKDIR /home/$USERNAME

CMD ["/usr/sbin/sshd", "-D"]
SHELL ["/bin/bash", "-c"]
