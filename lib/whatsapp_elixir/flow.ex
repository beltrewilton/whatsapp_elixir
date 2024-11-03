defmodule WhatsappElixir.Flow do
  @moduledoc """
  Module to handle WhatsApp flow.
  """

  require Logger
  alias WhatsappElixir.HTTP
  alias WhatsappElixir.Static

  @endpoint "messages"

  def send_flow(to, data, custom_config \\ [], opts \\ []) do
    flow_id = Keyword.get(opts, :flow_id)
    cta = Keyword.get(opts, :cta)
    screen = Keyword.get(opts, :screen)

    header = Keyword.get(opts, :header, "Flow message header")
    body = Keyword.get(opts, :body, "Flow message body")
    footer = Keyword.get(opts, :footer, "Flow message footer")
    mode = Keyword.get(opts, :mode, "draft")

    payload = %{
      "recipient_type" => "individual",
      "messaging_product" => "whatsapp",
      "to" => to,
      "type" => "interactive",
      "interactive" => %{
        "type" => "flow",
        "header" => %{
          "type" => "text",
          "text" => header
        },
        "body" => %{
          "text" => body
        },
        "footer" => %{
          "text" => footer
        },
        "action" => %{
          "name" => "flow",
          "parameters" => %{
            "mode" => mode,
            "flow_message_version" => "3",
            "flow_token" => UUID.uuid4(),
            "flow_id" => flow_id,
            "flow_cta" => cta,
            "flow_action" => "navigate",
            "flow_action_payload" => %{
              "screen" => screen,
              "data" => data
            }
          }
        }
      }
    }

    Logger.info("Sending flow to #{to}")

    case HTTP.post(@endpoint, payload, custom_config) do
      {:ok, response} ->
        Logger.info("Flow sent to #{to}")
        {:ok, response}

      {:error, response} ->
        Logger.error("Flow not sent to #{to}")
        Logger.error("Response: #{inspect(response)}")
        {:error, response}
    end
  end

  def read() do
    data = %{
      "encrypted_flow_data" =>
        "23Oj6TJZsqJiow5YWa4iwxdf0CzNlE+j25JNHWuHWIDxYeh2qqTKzU20W5+/EIruiuBWW/egumBIwxf cjRLpL3aDwS4mnSh4wOkm8t5OdJzCk/UIx7IC0h5PEHTiLMW1IJ3y/+W2OP5T4aQpuiM/LX04wLnACQZ zSzLeDfwEFLsVSdTpy/Ht8LXucXRl15fprkPHggWx88BwM2ylTwRP8Bt3H8R9x2PX9gfL32SKeTp6Lis 1Frv0hkfyFeZNtm22b6iqP8t4UgOecVYbVQl0ZTysZfK+IHEUX5k0kL5cpiRUmt9BYX4lG68uL9Vba1N DZkPDYbKBo+rMqHctgupVEX2d170Cc2YvFUdUvb9LhR+FfkZHcVp/K1mAMo45/zyEvS5JIfhM/BkTrY7 A8nd34JW9cog2SiI0TWnF0QEjFF5IezHlUEhZfHUWNw3TWk6aWgyKWHbFvFTqpqI41HQBcuJQDlxLLTo wPoQYuluMe2PpyoUJxS1X",
      "encrypted_aes_key" =>
        "C7RUBAY9QpMH9Sb6+FZxRQjkZXrTku4khZWwIQMjtuQTaZn7Ep15XAjDT9Ls2N/BbWbxN8QCh+0EZ8e +hUGsWMcfqVmhGTcCzWK2lV0m6pOyH4vldJeAQYF6yRtZMnCc9icMbcEzS1uAVFAdqoqKCDNGgu2o0l9 o6jtgZTBziSVvSV+AdauTnlsYPFz+vPddl5fv+FK7GX+hU6e2u899qDhzSruZMjaARe52kvE50YNPQXW vb2CkuQB5+ZpOCJNh60/ddVwuCxiitR9jQDp72sOowEs5MMvZoPQYEcPIhxBN72wqXpLIVjNmsCfuYzk 9bGMPOb71rgQqmd2DLCMwdQ==",
      "initial_vector" => "fAkALMkjd2DeAOQDPvMLdQ=="
    }

    passphrase = System.get_env("PASSPHRASE")

    {:ok, private_key_pem} = File.read("/Users/beltre.wilton/apps/plex/.certs/private.pem")

    {:ok, python} =
      :python.start_link([
        {:python_path,
         ~c"/Users/beltre.wilton/apps/whatsapp_elixir/lib/whatsapp_elixir:/Users/beltre.wilton/miniforge3/envs/tars_env/lib/python3.10/site-packages/cryptography"},
        {:python, ~c'python3'}
      ])

    result = :python.call(python, :crypt, :decrypt_request, [data, private_key_pem, passphrase])
    result = elem(result, 0)
    result[~c"data"]
  end
end

defmodule Decryptor do
  @doc """
  Decrypts the request data.

  Args:
  - `data`: A map containing the encrypted flow data, encrypted AES key, and initial vector.

  Returns:
  - A tuple containing the decrypted data, AES key, and initial vector.
  """
  def decrypt_request(data) do
    # Read the request fields
    encrypted_flow_data_b64 = Map.get(data, "encrypted_flow_data")
    encrypted_aes_key_b64 = Map.get(data, "encrypted_aes_key")
    initial_vector_b64 = Map.get(data, "initial_vector")

    {:ok, private_key_pem} = File.read("/Users/beltre.wilton/apps/plex/.certs/private.pem")
    passphrase = System.get_env("PASSPHRASE")

    # Base64 decode the fields
    flow_data = Base.decode64(encrypted_flow_data_b64, ignore: :whitespace)
    iv = Base.decode64(initial_vector_b64, ignore: :whitespace)

    # Decrypt the AES encryption key
    encrypted_aes_key = Base.decode64(encrypted_aes_key_b64, ignore: :whitespace)
    private_key = load_private_key(private_key_pem, passphrase)

    aes_key =
      :public_key.decrypt_private(encrypted_aes_key, private_key, [:rsa_oaep_padding, :sha256])

    # Decrypt the Flow data
    encrypted_flow_data_body = binary_part(flow_data, 0, byte_size(flow_data) - 16)
    encrypted_flow_data_tag = binary_part(flow_data, byte_size(flow_data) - 16, 16)

    decryptor =
      :crypto.crypto_one_time_aead(
        :aes_128_gcm,
        aes_key,
        iv,
        encrypted_flow_data_body,
        encrypted_flow_data_tag,
        nil
      )

    decrypted_data = Jason.decode!(decryptor)

    {decrypted_data, aes_key, iv}
  end

  defp load_private_key(private_key_pem, passphrase) do
    :public_key.pem_decode(private_key_pem)
    |> Enum.find(fn {_, _, _} -> true end)
    |> elem(1)
    |> :public_key.pem_entry_decode(passphrase)
  end
end
